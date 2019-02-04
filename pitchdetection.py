#! /usr/bin/env python
import pyaudio
import wave
import numpy as np
from aubio import pitch

from math import log, pow

A4 = 440
C0 = A4*pow(2, -4.75)
name = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

def pitch_to_note(freq):
    h = round(12*log(freq/C0, 2))
    octave = int(h // 12)
    n = int(h % 12)
    return name[n] + str(octave)

CHUNK = 1024
FORMAT = pyaudio.paFloat32
CHANNELS = 1
RATE = 44100
RECORD_SECONDS = 1000
WAVE_OUTPUT_FILENAME = "output.wav"

p = pyaudio.PyAudio()

stream = p.open(format=FORMAT,
                channels=CHANNELS,
                rate=RATE,
                input=True,
                frames_per_buffer=CHUNK)

print("* recording")

frames = []

# Pitch
tolerance = 0.2
downsample = 1
win_s = 4096 // downsample # fft size
hop_s = 1024  // downsample # hop size
pitch_o = pitch("yin", win_s, hop_s, RATE)
pitch_o.set_unit("Hz")
pitch_o.set_tolerance(tolerance)

prevNote = 'x'
prevPrint = 'x'
noteCounter = 0
for i in range(0, int(RATE / CHUNK * RECORD_SECONDS)):
    buffer = stream.read(CHUNK)
    frames.append(buffer)

    signal = np.fromstring(buffer, dtype=np.float32)
    pitch = pitch_o(signal)[0]
    confidence = pitch_o.get_confidence()
    if pitch > 0:
        note = pitch_to_note(pitch)
    else:
        note = None

    if confidence > 0.9 and not note is None:
        print("{} / {} / {}".format(pitch, note, confidence))
        # if note == prevNote:
        #     noteCounter += 1
        # else:
        #     noteCounter = 0
        # prevNote = note
        #
        # if noteCounter>4 and not prevPrint == note:
        #     print(note)
        #
        #
        #     prevPrint = note


print("* done recording")

stream.stop_stream()
stream.close()
p.terminate()

wf = wave.open(WAVE_OUTPUT_FILENAME, 'wb')
wf.setnchannels(CHANNELS)
wf.setsampwidth(p.get_sample_size(FORMAT))
wf.setframerate(RATE)
wf.writeframes(b''.join(frames))
wf.close()
