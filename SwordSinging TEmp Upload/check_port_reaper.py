import socket

IP = "10.7.65.105"
PORT = 8000

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((IP, PORT))

print(f"Listening for incoming packets on {IP}:{PORT}...")
print("Run your test_reaper_bridge.py script in another PowerShell window to see if packets arrive here.")

try:
    while True:
        data, addr = sock.recvfrom(1024)
        print(f"Received {len(data)} bytes from {addr}: {data}")
except KeyboardInterrupt:
    print("\nStopped listener.")