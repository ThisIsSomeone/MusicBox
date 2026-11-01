
import numpy as np
import sounddevice as sd
import simul_sensor

SAMPLE_RATE = 44100
BLOCK_SIZE = 512
VOLUME = 0.12

frequency = 220.0
phase = 0.0

def audio_callback(outdata, frames, time, status):
    global phase, frequency

    # Generate a continuous sine wave
    increments = 2 * np.pi * frequency / SAMPLE_RATE
    phases = phase + increments * np.arange(frames)

    audio = VOLUME * np.sin(phases)
    phase = (phases[-1] + increments) % (2 * np.pi)

    outdata[:, 0] = audio
    outdata[:, 1] = audio

# Start audio
stream = sd.OutputStream(
    samplerate=SAMPLE_RATE,
    blocksize=BLOCK_SIZE,
    channels=2,
    callback=audio_callback
)

stream.start()

print("Sword sound running. Press Ctrl+C to stop.")

try:
    while True:
        data = simul_sensor.get_sensor_data()

        # Map X angle (-180 to 180) to pitch (110 to 440 Hz)
        angle_x = data["angle"]["x"]
        frequency = 110 + (angle_x + 180) * (330 / 360)

        print(f"Angle: {angle_x:7.2f} | Pitch: {frequency:7.2f} Hz")

except KeyboardInterrupt:
    print("\nStopping...")

finally:
    stream.stop()
    stream.close()
