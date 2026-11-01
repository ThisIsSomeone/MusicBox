import json
import socket
import time
import mido

# Find and open MIDI port
ports = mido.get_output_names()
print(f"Available MIDI ports: {ports}")
target_port = next((p for p in ports if "SwordPort" in p or "loopMIDI" in p), ports[0])
print(f"Binding to MIDI: {target_port}")
midi_out = mido.open_output(target_port)

# UDP Listener Configuration
LISTEN_IP = "127.0.0.1"
LISTEN_PORT = 7001

server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server_socket.bind((LISTEN_IP, LISTEN_PORT))
server_socket.setblocking(False)

print(f"\nListening for raw UDP packets on {LISTEN_IP}:{LISTEN_PORT}...\n")

if __name__ == "__main__":
    current_playing_note = None
    try:
        while True:
            try:
                packet, addr = server_socket.recvfrom(1024)
                message = packet.decode('utf-8')
                print(f"Received UDP Packet: {message}")
                
                # Parse data to test note trigger
                data = json.loads(message)
                accel = data.get("accel", {"z": 9.81})
                
                # Check movement threshold using diagnostic logic
                is_moving = accel["z"] > 10.0
                note = 60 # Root note C4
                
                if is_moving and current_playing_note != note:
                    if current_playing_note is not None:
                        midi_out.send(mido.Message('note_off', note=current_playing_note, velocity=64))
                    current_playing_note = note
                    midi_out.send(mido.Message('note_on', note=current_playing_note, velocity=100))
                    print(f"NOTE ON: {current_playing_note}")
                    
                elif not is_moving and current_playing_note is not None:
                    midi_out.send(mido.Message('note_off', note=current_playing_note, velocity=64))
                    print("NOTE OFF")
                    current_playing_note = None
                    
            except BlockingIOError:
                time.sleep(0.01)
            except Exception as e:
                print(f"Parsing Error: {e}")
                
    except KeyboardInterrupt:
        if current_playing_note is not None:
            midi_out.send(mido.Message('note_off', note=current_playing_note, velocity=64))
        midi_out.close()
        print("\nStopped.")