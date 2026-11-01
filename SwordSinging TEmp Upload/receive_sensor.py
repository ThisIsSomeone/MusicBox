import socket
import json

SIMULATOR_MODE = True  # False = Pico W, True = simulator
PC_PORT = 5005

if SIMULATOR_MODE:
    import simul_sensor

    print("Using simulated sensor data...")

    while True:
        data = simul_sensor.get_sensor_data()

        print("\n--- SENSOR DATA ---")
        print("Acceleration:", data["accel"])
        print("Gyroscope:   ", data["gyro"])
        print("Angles:      ", data["angle"])

else:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("0.0.0.0", PC_PORT))

    print("Waiting for Pico W sensor data...")

    while True:
        message, address = sock.recvfrom(2048)

        try:
            data = json.loads(message.decode())

            print("\n--- SENSOR DATA ---")
            print("Acceleration:", data["accel"])
            print("Gyroscope:   ", data["gyro"])
            print("Angles:      ", data["angle"])

        except (ValueError, KeyError):
            print("Invalid message:", message)