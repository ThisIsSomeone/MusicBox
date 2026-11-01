import numpy as np
import sounddevice as sd
import random
import time

# Audio settings
SAMPLE_RATE = 44100
BLOCK_SIZE = 1024

# State variables for continuous sound generation
phase = 0.0
current_freq = 220.0  # Starting pitch (A3)
target_freq = 220.0
current_intensity = 0.15  # Volume/drive

def update_simulation():
    """Generates simulated motion data similar to simul_sensor.py"""
    return {
        "accel": {
            "x": random.uniform(-16, 16),
            "y": random.uniform(-16, 16),
            "z": random.uniform(-16, 16)
        },
        "angle": {
            "x": random.uniform(-180, 180),
            "y": random.uniform(-180, 180),
            "z": random.uniform(-180, 180)
        }
    }

def audio_callback(outdata, frames, time_info, status):
    global phase, current_freq, target_freq, current_intensity
    
    if status:
        print(status, flush=True)

    # Smoothly interpolate frequency and intensity to avoid clicks
    current_freq += (target_freq - current_freq) * 0.1
    
    # Generate time array for the current block
    t = (phase + np.arange(frames)) / SAMPLE_RATE
    
    # Base clean tone (sine wave + subtle harmonic for electric guitar character)
    wave = np.sin(2 * np.pi * current_freq * t) + 0.3 * np.sin(2 * np.pi * (current_freq * 2) * t)
    
    # Apply soft clipping / light overdrive if intensity is high
    if current_intensity > 0.25:
        wave = np.tanh(wave * (1.0 + (current_intensity - 0.25) * 4))
    else:
        wave = wave * 0.7

    # Apply volume envelope
    audio_block = wave * current_intensity
    
    # Shape into stereo (2 channels)
    outdata[:] = np.column_stack((audio_block, audio_block))
    
    # Advance phase
    phase = (phase + frames) % SAMPLE_RATE

# Start the real-time audio stream
stream = sd.OutputStream(
    samplerate=SAMPLE_RATE,
    channels=2,
    blocksize=BLOCK_SIZE,
    callback=audio_callback
)

print("Starting live interactive sword sound generator...")
print("Press Ctrl+C to stop.\n")

with stream:
    try:
        while True:
            # Simulate receiving motion data every 0.1 seconds
            data = update_simulation()
            
            # Map angle X (-180 to 180) to frequency (approx 150 Hz to 450 Hz)
            angle_x = data["angle"]["x"]
            target_freq = 200 + ((angle_x + 180) / 360.0) * 300
            
            # Map acceleration magnitude to intensity / overdrive
            accel = data["accel"]
            accel_magnitude = np.sqrt(accel["x"]**2 + accel["y"]**2 + accel["z"]**2)
            # Normalize rough acceleration into an intensity factor
            current_intensity = min(0.3, max(0.05, accel_magnitude / 50.0))
            
            print(f"Angle X: {angle_x:6.1f}° | Freq: {target_freq:5.1f} Hz | Intensity: {current_intensity:.2f}", end="\r")
            
            time.sleep(0.1)
            
    except KeyboardInterrupt:
        print("\nStopping sound generator. Goodbye!")