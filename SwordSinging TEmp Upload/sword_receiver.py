import json
import socket
import math
from pythonosc import udp_client

# Network Configuration for REAPER
REAPER_IP = "127.0.0.1"
REAPER_PORT = 8000
client = udp_client.SimpleUDPClient(REAPER_IP, REAPER_PORT)

# UDP Listener Configuration
LISTEN_IP = "127.0.0.1"
LISTEN_PORT = 7001

server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server_socket.bind((LISTEN_IP, LISTEN_PORT))
server_socket.setblocking(False)

print(f"=== Sword Note Engine Active ===")
print(f"Listening for sensor JSON, routing musical data to REAPER...\n")

def process_to_music(data):
    accel = data.get("accel", {"x": 0, "y": 0, "z": 9.81})
    angle = data.get("angle", {"x": 0, "y": 0, "z": 0})
    
    # 1. Movement Energy (Are you swinging or still?)
    raw_accel_mag = math.sqrt(accel["x"]**2 + accel["y"]**2 + accel["z"]**2)
    movement_energy = max(0.0, raw_accel_mag - 9.81)
    is_moving = movement_energy > 2.0  # Threshold for active movement

    # 2. Orientation Pitch Canvas (Where is the sword aimed vertically?)
    # Map Angle X (-90 to 90 degrees) to a continuous pitch value (0.0 to 1.0)
    pitch_value = max(0.0, min(1.0, (angle["x"] + 90.0) / 180.0))

    return pitch_value, is_moving

if __name__ == "__main__":
    try:
        while True:
            try:
                packet, addr = server_socket.recvfrom(1024)
                data = json.loads(packet.decode('utf-8'))
                
                pitch, moving = process_to_music(data)
                
                # Instead of volume, send pitch/frequency data to the synth parameter
                client.send_message("/track/1/fx/1/p/2", pitch) # Assuming parameter 2 is pitch/frequency
                
                # Send a note trigger / gate signal based on whether you are actively moving
                gate_signal = 1 if moving else 0
                client.send_message("/track/1/fx/1/p/3", gate_signal) # Gate/trigger parameter

                status_text = "PLAYING (Moving) ⚔️" | "IDLE (Humming) 💤" if moving else "IDLE (Humming) 💤"
                print(f"Pitch/Note Value: {pitch:.2f} | State: {status_text}", end="\r")
                
            except BlockingIOError:
                pass
                
    except KeyboardInterrupt:
        print("\nReceiver stopped.")