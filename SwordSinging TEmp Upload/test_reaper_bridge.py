import time
import random
from pythonosc import udp_client

# REAPER listens on localhost via OSC
REAPER_IP = "10.7.65.105"
REAPER_PORT = 8000  

client = udp_client.SimpleUDPClient(REAPER_IP, REAPER_PORT)

print("Sending simulated sword movement data to REAPER via OSC...")
print("Press Ctrl+C to stop.\n")

try:
    while True:
        # Simulate motion intensity (0.0 to 1.0) based on random acceleration
        intensity = round(random.uniform(0.0, 1.0), 2)
        
        # Send an OSC message to REAPER (controlling track 1 volume as a test)
        client.send_message("/track/1/volume", intensity)
        
        print(f"Sent simulated intensity to REAPER: {intensity}", end="\r")
        time.sleep(0.1)

except KeyboardInterrupt:
    print("\nStopped bridge.")