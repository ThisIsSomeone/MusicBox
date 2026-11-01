import json
import socket
import time
import math
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

print(f"\nListening for UDP packets on {LISTEN_IP}:{LISTEN_PORT}...\n")

def data_to_midi(data):
    accel = data.get("accel", {"x": 0, "y": 0, "z": 9.81})
    angle = data.get("angle", {"x": 0, "y": 0, "z": 0})
    
    # Calculate movement energy (threshold tuned to simulator output)
    raw_accel_mag = math.sqrt(accel["x"]**2 + accel["y"]**2 + accel["z"]**2)
    movement_energy = max(0.0, raw_accel_mag - 9.81)
    is_moving = movement_energy > 1.5  

    # Map tilt angle X (-60 to 60 degrees) to a musical scale index
    angle_x = max(-60.0, min(60.0, angle["x"]))
    normalized_pitch = (angle_x + 60.0) / 120.0
    
    # A minor pentatonic scale offsets from root C4 (Note 60)
    pentatonic_offsets = [0, 3, 5, 7, 10, 12, 15, 17]
    scale_index = int(normalized_pitch * (len(pentatonic_offsets) - 1))
    midi_note = 60 + pentatonic_offsets[scale_index]

    return midi_note, is_moving

if __name__ == "__main__":
    current_playing_note = None
    try:
        while True:
            try:
                packet, addr = server_socket.recvfrom(1024)
                message = packet.decode('utf-8')
                
                data = json.loads(message)
                note, moving = data_to_midi(data)
                
                if moving and current_playing_note != note:
                    if current_playing_note is not None:
                        midi_out.send(mido.Message('note_off', note=current_playing_note, velocity=64))
                    
                    current_playing_note = note
                    midi_out.send(mido.Message('note_on', note=current_playing_note, velocity=100))
                    print(f"NOTE ON: {current_playing_note} (Angle: {data.get('angle', {}).get('x', 0):.1f} deg)")
                    
                elif not moving and current_playing_note is not None:
                    midi_out.send(mido.Message('note_off', note=current_playing_note, velocity=64))
                    print("NOTE OFF (Still)")
                    current_playing_note = None
                
            except BlockingIOError:
                time.sleep(0.01)
            except Exception as e:
                print(f"Parsing Error: {e}")
                
    except KeyboardInterrupt:
        if current_playing_note is not None:
            midi_out.send(mido.Message('note_off', note=current_playing_note, velocity=64))
        midi_out.close()
        print("\nMIDI Engine stopped.")