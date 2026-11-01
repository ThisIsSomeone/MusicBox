import socket
import json
import time
import msvcrt
import os

# UDP Configuration
TARGET_IP = "127.0.0.1"
TARGET_PORT = 7001

client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Full Sensor State Variables
is_active_mode = False
accel_x = 0.0
accel_y = 0.0
accel_z = 9.81  # Base gravity

angle_x = 0.0   # Pitch
angle_y = 0.0   # Roll
angle_z = 0.0   # Yaw

gyro_x = 0.0
gyro_y = 0.0
gyro_z = 0.0

print("=== Full Sensor Matrix Simulator ===")
print("Controls:")
print("  [Space]       : Toggle Active / Still mode (Movement Trigger)")
print("  [W / S]       : Accel Z +/- (Thrust / Lift)")
print("  [A / D]       : Accel X +/- (Sway Left / Right)")
print("  [Q / E]       : Accel Y +/- (Forward / Backward)")
print("  [I / K]       : Angle X (Pitch) +/-")
print("  [J / L]       : Angle Y (Roll) +/-")
print("  [U / O]       : Angle Z (Yaw) +/-")
print("  [ESC]         : Exit simulator\n")
print("Streaming full telemetry matrix to port 7001...\n")

try:
    while True:
        # Non-blocking key check for Windows
        if msvcrt.kbhit():
            key = msvcrt.getch().decode('utf-8', errors='ignore').lower()
            
            if key == '\x1b':  # ESC key
                break
            elif key == ' ':
                is_active_mode = not is_active_mode
            elif key == 'w':
                accel_z += 1.0
            elif key == 's':
                accel_z -= 1.0
            elif key == 'a':
                accel_x += 1.0
            elif key == 'd':
                accel_x -= 1.0
            elif key == 'q':
                accel_y += 1.0
            elif key == 'e':
                accel_y -= 1.0
            elif key == 'i':
                angle_x = max(-60.0, min(60.0, angle_x + 10.0))
            elif key == 'k':
                angle_x = max(-60.0, min(60.0, angle_x - 10.0))
            elif key == 'j':
                angle_y = max(-60.0, min(60.0, angle_y + 10.0))
            elif key == 'l':
                angle_y = max(-60.0, min(60.0, angle_y - 10.0))
            elif key == 'u':
                angle_z = (angle_z + 15.0) % 360.0
            elif key == 'o':
                angle_z = (angle_z - 15.0) % 360.0

        # Enforce baseline gravity if not in active manual override
        target_accel_z = accel_z if is_active_mode else 9.81

        # Construct complete DFRobot SEN0386 payload structure
        sensor_data = {
            "accel": {"x": accel_x, "y": accel_y, "z": target_accel_z},
            "gyro": {"x": gyro_x, "y": gyro_y, "z": gyro_z},
            "angle": {"x": angle_x, "y": angle_y, "z": angle_z}
        }

        # Broadcast over UDP
        message = json.dumps(sensor_data)
        client_socket.sendto(message.encode('utf-8'), (TARGET_IP, TARGET_PORT))

        # Live telemetry console dashboard
        status_str = "ACTIVE" if is_active_mode else "STILL "
        print(
            f"[{status_str}] "
            f"Acc[X:{accel_x:4.1f}, Y:{accel_y:4.1f}, Z:{target_accel_z:5.1f}] | "
            f"Ang[X:{angle_x:5.1f}, Y:{angle_y:5.1f}, Z:{angle_z:5.1f}]",
            end='\r'
        )
        
        time.sleep(0.05)  # 20 updates per second

except KeyboardInterrupt:
    print("\nSimulator stopped.")
finally:
    client_socket.close()