import socket

PC_PORT = 8080

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", PC_PORT))

print("Listening for Pico data on port 8080...")

while True:
    message, address = sock.recvfrom(2048)
    print("From", address, ":", message.decode())