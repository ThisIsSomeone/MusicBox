import numpy as np
import sounddevice as sd

SAMPLE_RATE = 44100
DURATION = 3
FREQUENCY = 440
VOLUME = 0.15

# Generate the tone
t = np.arange(int(SAMPLE_RATE * DURATION)) / SAMPLE_RATE
audio = np.sin(2 * np.pi * FREQUENCY * t)

# Fade in and out to avoid clicks
fade_length = int(SAMPLE_RATE * 0.3)
fade_in = np.linspace(0, 1, fade_length)
fade_out = np.linspace(1, 0, fade_length)

audio[:fade_length] *= fade_in
audio[-fade_length:] *= fade_out

# Set volume
audio *= VOLUME

# Play
sd.play(audio, SAMPLE_RATE)
sd.wait()