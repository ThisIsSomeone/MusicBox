import json
import socket
import math
import time
import mido

# UDP Listener Configuration for Sensor JSON
LISTEN_IP = "127.0.0.1"
LISTEN_PORT = 7001

server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server_socket.bind((LISTEN_IP, LISTEN_PORT))
server_socket.setblocking(False)

print("=== Sword MIDI Instrument Engine (Win 10 & 11 Compatible) ===")

def connect_midi():
    """Scan and connect to SwordPort, loopMIDI, or any virtual port."""
    while True:
        ports = mido.get_output_names()
        print(f"Scanning MIDI outputs... Found: {ports}")
        
        target_port = None
        for port in ports:
            # Match SwordPort, loopMIDI, or Virtual ports
            if "SwordPort" in port or "loopMIDI" in port or "Virtual" in port:
                target_port = port
                break
                
        if target_port:
            print(f"Successfully bound to virtual port: {target_port}")
            try:
                return mido.open_output(target_port)
            except Exception as e:
                print(f"Failed to open {target_port}: {e}")
                
        print("Waiting for valid MIDI port to open...")
        time.sleep(2.0)

# Establish connection safely before listening to data
midi_out = connect_midi()

print("\nListening for sensor data, translating movement into notes...\n")

def data_to_midi(data):
    accel = data.get("accel", {"x": 0, "y": 0, "z": 9.81})
    angle = data.get("angle", {"x": 0, "y": 0, "z": 0})
    
    # Calculate movement energy (G-force magnitude minus gravity)
    raw_accel_mag = math.sqrt(accel["x"]**2 + accel["y"]**2 + accel["z"]**2)
    movement_energy = max(0.0, raw_accel_mag - 9.81)
    is_moving = movement_energy > 2.5  # Strike threshold

    # Map tilt angle X (-60 to 60 degrees) to a musical scale index
    angle_x = max(-60.0, min(60.0, angle["x"]))
    normalized_pitch = (angle_x + 60.0) / 120.0
    
    # A minor pentatonic scale offset notes from root C4 (Note 60)
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
                data = json.loads(packet.decode('utf-8'))
                
                note, moving = data_to_midi(data)
                
                if moving and current_playing_note != note:
                    if current_playing_note is not None:
                        midi_out.send(mido.Message('note_off', note=current_playing_note, velocity=64))
                    
                    current_playing_note = note
                    midi_out.send(mido.Message('note_on', note=current_playing_note, velocity=100))
                    print(f"⚔️ NOTE ON: {current_playing_note} (Angle X mapped)")
                    
                elif not moving and current_playing_note is not None:
                    midi_out.send(mido.Message('note_off', note=current_playing_note, velocity=64))
                    print(f"💤 NOTE OFF (Still)")
                    current_playing_note = None
                
            except BlockingIOError:
                pass
                
    except KeyboardInterrupt:
        if current_playing_note is not None:
            midi_out.send(mido.Message('note_off', note=current_playing_note, velocity=64))
        midi_out.close()
        print("\nMIDI Engine stopped.")