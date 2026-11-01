import json
import random
import time
import socket
import msvcrt

# UDP target configuration for our local bridge
TARGET_IP = "127.0.0.1"
TARGET_PORT = 7001  # Port where our Python receiver listens for the Pico JSON

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

def get_mock_sensor_packet(moving=False):
    if moving:
        # Active movement: dynamic acceleration, gyro rotation, and varying angles
        accel = {
            "x": round(random.uniform(-6.0, 6.0), 2),
            "y": round(random.uniform(-6.0, 6.0), 2),
            "z": round(random.uniform(2.0, 14.0), 2)
        }
        gyro = {
            "x": round(random.uniform(-400, 400), 2),
            "y": round(random.uniform(-400, 400), 2),
            "z": round(random.uniform(-400, 400), 2)
        }
        angle = {
            "x": round(random.uniform(-60, 60), 2),
            "y": round(random.uniform(-90, 90), 2),
            "z": round(random.uniform(-180, 180), 2)
        }
    else:
        # Idle/Still: resting state with gravity on Z axis and zeroed motion
        accel = {"x": 0.0, "y": 0.0, "z": 9.81}
        gyro = {"x": 0.0, "y": 0.0, "z": 0.0}
        angle = {"x": 0.0, "y": 0.0, "z": 0.0}

    return {
        "accel": accel,
        "gyro": gyro,
        "angle": angle
    }

if __name__ == "__main__":
    print("=== Pico W Sensor Mock Streamer Active ===")
    print("Hold any key to simulate ACTIVE SWORD MOVEMENT. Release for idle stillness. (Ctrl+C to exit)\n")
    
    try:
        while True:
            # Check if user is pressing a key to simulate movement
            is_moving = msvcrt.kbhit()
            if is_moving:
                msvcrt.getch() # Clear buffer
            
            sensor_data = get_mock_sensor_packet(moving=is_moving)
            
            # Convert to JSON string
            json_data = json.dumps(sensor_data)
            
            # Send over UDP
            sock.sendto(json_data.encode('utf-8'), (TARGET_IP, TARGET_PORT))
            
# Corrected line:
            status = "STILL" if not is_moving else "MOVING"
            print(f"Status: {status:<10} | Payload: {json_data}", end="\r")
            
            time.sleep(0.1) # 10 updates per second
            
    except KeyboardInterrupt:
        print("\nMock streamer stopped.")