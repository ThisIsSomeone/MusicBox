# Swordsinging: Real-Time Motion Sensor to MIDI Bridge

A cross-platform (Windows 10/11) Python system that converts motion sensor data (simulating a sword) into real-time MIDI output for VST instruments in REAPER.

## Data Pipeline
`simul_sensor_full.py` (UDP broadcast on port 7001) -> `sword_midi_bridge.py` (MIDI translation & pentatonic scaling) -> loopMIDI (Virtual Port) -> REAPER.

## Prerequisites & Environment
* **OS:** Windows 10 / 11
* **Python:** 3.x with `mido`, `python-rtmidi`, and standard libraries (`socket`, `json`, `math`, `msvcrt`).
* **MIDI Routing:** [loopMIDI](https://www.tobias-eranger.de/en/loopmidi.html) installed and configured with a virtual port named **`SwordPort 3`**.
* **DAW:** REAPER with a virtual instrument plugin loaded.

## Setup & Running Instructions

### Step 1: Create the Virtual MIDI Port
1. Open **loopMIDI**.
2. Ensure a virtual port named **`SwordPort 3`** is created and active.

### Step 2: Configure REAPER
1. Open REAPER and go to **Options > Preferences > Audio > MIDI Devices**.
2. Under **MIDI inputs**, find **`SwordPort 3`** and set it to **Enabled** (and optionally **Enabled + Control**).
3. Create a track, load your virtual instrument plugin, set the track input to **MIDI > SwordPort 3 > All Channels**, and **Record Arm** the track with monitoring enabled.

### Step 3: Run the Bridge Script
Start your bridge script (`sword_midi_bridge.py`) first so it binds to the virtual MIDI output and listens for incoming UDP packets on port 7001:
```powershell
python3 .\sword_midi_bridge.py