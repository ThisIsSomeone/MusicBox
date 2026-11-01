import socket
import json
import time
import math
import msvcrt

# UDP Configuration
TARGET_IP = "127.0.0.1"
TARGET_PORT = 7001

client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

print("=== Pico W Sensor Mock Streamer Active ===")
print(f"Targeting UDP -> {TARGET_IP}:{TARGET_PORT}")
print("Press and hold ANY KEY to simulate ACTIVE SWORD MOVEMENT. Release for idle stillness. (Ctrl+C to exit)\n")

try:
    counter = 0
    while True:
        is_active = msvcrt.kbhit()
        
        if is_active:
            msvcrt.getch()
            accel_x = 3.5
            accel_y = 2.0
            accel_z = 11.5  # High-magnitude movement exceeding threshold
            angle_x = 50.0 * math.sin(counter * 0.2)
            status_text = "ACTIVE"
        else:
            accel_x = 0.0
            accel_y = 0.0
            accel_z = 9.81  # Idle gravity
            angle_x = 0.0
            status_text = "STILL"

        sensor_data = {
            "accel": {"x": accel_x, "y": accel_y, "z": accel_z},
            "gyro": {"x": 0.1, "y": 0.0, "z": 0.2},
            "angle": {"x": angle_x, "y": 0.0, "z": 0.0}
        }

        message = json.dumps(sensor_data)
        client_socket.sendto(message.encode('utf-8'), (TARGET_IP, TARGET_PORT))

        print(f"Status: {status_text:8} | Payload: {message}")
        
        counter += 1
        time.sleep(0.05)

except KeyboardInterrupt:
    print("\nSimulator stopped.")
    client_socket.close()