import time
import random
import msvcrt
from pythonosc import udp_client

# Network Configuration
REAPER_IP = "10.7.65.105"
REAPER_PORT = 8000
client = udp_client.SimpleUDPClient(REAPER_IP, REAPER_PORT)

def get_idle_data():
    """Simulates a resting sword with minor stabilization noise."""
    return {
        "intensity": 0.5,  # Keeps a safe middle value instead of 0 silence
        "slashing": 0
    }

def get_slash_data():
    """Simulates a high-energy sword slash."""
    return {
        "intensity": 1.0,
        "slashing": 1
    }

if __name__ == "__main__":
    print("=== Sword Singing Bridge Active ===")
    print("Press [SPACEBAR] in this window to simulate a sword slash. Press Ctrl+C to exit.\n")
    
    try:
        while True:
            # Check for keyboard input to simulate a slash
            is_slash = False
            if msvcrt.kbhit():
                key = msvcrt.getch()
                if key == b' ':
                    is_slash = True

            # Get data based on current state
            if is_slash:
                data = get_slash_data()
                print("\n⚡ SLASH DETECTED! Sending trigger event.")
            else:
                data = get_idle_data()

            # Optional: If you mapped track volume, this keeps it at a healthy level. 
            # Better yet, map this to an FX parameter (like a filter or distortion knob) in REAPER!
            client.send_message("/track/1/volume", data["intensity"])
            
            # Send discrete event trigger for slashes
            client.send_message("/trigger/slash", data["slashing"])

            # Status output
            print(f"State: {'SLASH' if data['slashing'] else 'Idle'} | Intensity: {data['intensity']}", end="\r")
            
            time.sleep(0.1) # 10 updates per second
            
    except KeyboardInterrupt:
        print("\nBridge stopped.")