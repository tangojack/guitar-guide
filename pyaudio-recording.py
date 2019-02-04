import pyaudio
import wave
import time
import struct

CHUNK = 1024 # number of frames per buffer
FORMAT = pyaudio.paFloat32 # bit depth of audio
CHANNELS = 1 # mono or stereo
RATE = 44100 # number of samples per second
RECORD_SECONDS = 5
WAVE_OUTPUT_FILENAME = "output.wav"

p = pyaudio.PyAudio() # object of class pyaudio.PyAudio is instantiated
                      # starts PortAudio

# open an audio stream
stream = p.open(format=FORMAT,
                channels=CHANNELS,
                rate=RATE,
                input=True,
                frames_per_buffer=CHUNK)
# frames per buffer is the length of the audio buffer

# use stream callback
print("* recording")
frames = []
odf_frames = []
for i in range(0, int(RATE / CHUNK * RECORD_SECONDS)):
    frame = stream.read(CHUNK)
    print(len(frame))
    odf_frame = get_odf(frame)
    df_frames.append(odf_frame)
    if (len(odf_frames) > 3):
        if (odf_frame[-2] > odf_frame[-1] && odf_frame[-2] > odf_frame[-3]):
            if (odf_frame[-1] > threshold):
                print("ONSET BITCH")

    frames.append(data)

print("* done recording")

def get_odf(frame):
    data_int = struct.unpack(str(2 * CHUNK) + 'B', frame)
    E = 0
    for x in data_int:
        E = E + (x ** 2)


stream.stop_stream()
stream.close()
p.terminate()
