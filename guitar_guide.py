import multiprocessing
import pyaudio
import wave
import time
import utils
import struct
import numpy as np
from aubio import pitch
from math import log2, pow
from PIL import Image
from PIL import ImageTk
import tkinter as tki
import cv2
import threading
import random

def audio_record(stop_audio_process, queue):
    #parameters for recording the sound
    CHUNK = 1024
    FORMAT = pyaudio.paInt16
    CHANNELS = 1
    RATE = 44100
    p = pyaudio.PyAudio() # object of class pyaudio.PyAudio is instantiated starts PortAudio
    # open an audio stream
    stream = p.open(format=FORMAT,
                    channels=CHANNELS,
                    rate=RATE,
                    input=True,
                    frames_per_buffer=CHUNK)
    # frames per buffer is the length of the audio buffer

    print("* recording")

    # need this to compute energy values of odf
    squarer = lambda t: t ** 2
    square = np.vectorize(squarer)

    data_int = []
    data_odf = []
    thresholds = [0]

    onsets_y = []
    onsets_x = []

    # parameters for onset detection
    alpha = 13
    beta = 15
    m = 20

    # start of recording
    i = 0
    combined_data = []
    while stop_audio_process.value is 0:
        data = np.frombuffer(stream.read(CHUNK), dtype=np.int16)
        combined_data.extend(data)
        data_int = np.concatenate((data_int, data))
        data_energy_value = np.sum(square(data))
        if i > 0:
            data_odf.append(abs(data_energy_value - data_energy_value_previous))
        else:
            data_odf.append(data_energy_value)
        data_energy_value_previous = data_energy_value
        if i >= m:
            data_odf_previous_m_median = np.median(data_odf[i-m:i])
            data_odf_previous_m_mean = np.mean(data_odf[i-m:i])
            thresholds.append((beta * data_odf_previous_m_median) + (alpha * data_odf_previous_m_mean))
        elif i > 0:
            data_odf_previous_m_median = np.median(data_odf[0:i])
            data_odf_previous_m_mean = np.mean(data_odf[0:i])
            thresholds.append((beta * data_odf_previous_m_median) + (alpha * data_odf_previous_m_mean))

        if i > 1:
            if (data_odf[i-1] > data_odf[i] and data_odf[i-1] > data_odf[i-2]):
                if (data_odf[i-1] > thresholds[i-1]):
                    kuch_bhi = random.randint(1,1000)
                    print(kuch_bhi, " Onset")
                    onsets_y.append(data_odf[i-1])
                    onsets_x.append(i-1)
                    # audio buffer at that instant is being used for pitch analysis
                    pitch_data = np.array(combined_data[-(3*len(data)):])
                    float_data = pitch_data.astype(np.float32)
                    pitch_1 = utils.freq_from_autocorr(float_data)
                    if pitch_1 > 0:
                        note = utils.pitch_to_note(pitch_1)
                    else:
                        note = None
                    queue.put(note)
        i = i + 1

    print("* done recording")
    stream.stop_stream()
    stream.close()
    p.terminate()

class GuitarGuide:
    def __init__(self, skin_color_histogram):
        self.skin_color_histogram = skin_color_histogram
        self.video_frame = None
        self.video_cap = None
        # Initializing Tkinter's root widget. Can access other widgets with the root
        self.root = tki.Tk()
        self.roi = None
        # Multiprocessing queue to communicate between the Video Thread and the Audio Process
        self.queue = multiprocessing.Queue()
        self.images_array = []
        stop_btn = tki.Button(self.root, text="Stop Process", command=self.stop_processes)
        stop_btn.pack(side="bottom", fill="both", padx=10, pady=10)

        start_btn = tki.Button(self.root, text="Start Video and Audio Capture", command=self.start_processes)
        start_btn.pack(side="bottom", fill="both", padx=10, pady=10)

        cycle_btn = tki.Button(self.root, text="Cycle", command=self.cycle_through_images)
        cycle_btn.pack(side="bottom", fill="both", padx=10, pady=10)

        # Adding the image of the Fretboard to the GUI
        fretboard_img = Image.open("images/fretboard.jpg")
        fretboard_img = fretboard_img.resize((1320, 400), Image.ANTIALIAS)
        fretboard_img = ImageTk.PhotoImage(fretboard_img)
        self.fretboard_label = tki.Label(self.root, image=fretboard_img)
        self.fretboard_label.image = fretboard_img
        self.fretboard_label.pack(side="bottom", fill="both", expand="yes")

        image = Image.fromarray(np.zeros((200, 712)))
        image = ImageTk.PhotoImage(image)
        self.panel = tki.Label(image=image)
        self.panel.image = image
        self.panel.pack(side="left", padx=10, pady=10)

        self.chord = tki.StringVar(self.root)
        # Dictionary with options
        choices = {'CMajor', 'DMinor', 'EMinor', 'FMajor', 'GMajor', 'AMinor'}
        self.chord.set('CMajor') # set the default option
        self.popupMenu = tki.OptionMenu(self.root, self.chord, *choices)
        self.popupMenu.pack(side="right", padx=10, pady=10)

        self.root.wm_title("Guitar Guide")
        self.root.wm_protocol("WM_DELETE_WINDOW", self.onClose)

        self.message = tki.Label(self.root, text="", font=("Calibri", 14))
        self.message.pack(side="top")

    def cycle_through_images(self):
        if self.images_array:
            img = self.images_array[self.image_counter]
            img = Image.fromarray(img)
            img = ImageTk.PhotoImage(img)
            self.fretboard_label.configure(image=img)
            self.fretboard_label.image = img
            self.image_counter = (self.image_counter + 1) % len(self.images_array)

    def start_processes(self):
        # Flag which can be set to False or True
        # self.q = multiprocessing.Queue()
        if self.video_cap is None:
            self.video_cap = cv2.VideoCapture(0)

        # This should be set to False for the Video Thread to run
        self.stop_video_thread = False
        self.video_thread = threading.Thread(target=self.video_record, args=())

        self.stop_audio_process = multiprocessing.Value('i', 0)
        self.audio_process = multiprocessing.Process(target=audio_record, args=(self.stop_audio_process, self.queue,))

        self.video_thread.start()
        self.audio_process.start()

    def stop_processes(self):
        self.stop_video_thread = True
        self.video_thread.join()

        self.stop_audio_process.value = 1
        self.audio_process.join()
        self.audio_process.terminate()

        while not self.queue.empty():
            self.queue.get()

        self.stop_audio_process.value = 0

        if not self.panel is None:
            self.panel.destroy()
            self.panel = None

        # Resetting the image to a black fretboard
        fretboard_img = Image.open("images/fretboard.jpg")
        fretboard_img = fretboard_img.resize((1320, 400), Image.ANTIALIAS)
        fretboard_img = ImageTk.PhotoImage(fretboard_img)
        self.fretboard_label.configure(image=fretboard_img)
        self.fretboard_label.image = fretboard_img

    def video_record(self):
        try:
            ret, self.video_frame = self.video_cap.read()
            height, width, _ = self.video_frame.shape

            # Capture only the bottom half of the webcam
            self.video_frame = self.video_frame[int(height/2):height, :]
            image_to_process = self.video_frame

            self.video_frame = cv2.resize(self.video_frame, (712, 200))
            self.video_frame = cv2.flip(self.video_frame, 1)
            image = cv2.cvtColor(self.video_frame, cv2.COLOR_BGR2RGB)
            image = Image.fromarray(image)

            image = ImageTk.PhotoImage(image)

            # if the panel is not None, we need to initialize it
            if self.panel is None:
                self.panel = tki.Label(image=image)
                self.panel.image = image
                self.panel.pack(side="left", padx=10, pady=10)
            # otherwise, simply update the panel
            else:
                self.panel.configure(image=image)
                self.panel.image = image

            # When an onset is detected the multiprocessing queue will have a value and will enter the if block
            if not self.queue.empty():
                note = self.queue.get()
                if not note is None:
                    # checking if note is in range of the guitar
                    octave = utils.get_trailing_number(note)
                    if not (octave <= 6 and octave >= 2):
                        self.message.config(text=note + " out of guitar range")
                    else:
                        # note is in the range of the guitar
                        # extracting the key
                        if len(note) is 3:
                            # this means its a sharp
                            key = note[0:2]
                        else:
                            key = note[0]

                        chord = self.chord.get()
                        if chord[1] is '#':
                            selected_key = chord[0:2]
                        else:
                            selected_key = chord[0]
                        # If it is not the root note of the chord the user selected, the user will try again until it is
                        if key is selected_key:
                            self.message.config(text=note + " is being played. The Chord Shapes are displayed below")
                            (string, fret) = utils.image_processing(image_to_process, note, self.skin_color_histogram)
                            # If there is no error in the Image Processing
                            if not string is -1:
                                # The fretboard image will now show the root note alond with the other notes to complete the chord
                                chords = utils.find_chords(chord, string, fret)
                                if not chords:
                                    self.message.config(text="No chord shapes found for the note being played")
                                else:
                                    self.images_array = []
                                    self.image_counter = 0
                                    self.images_array = utils.image_notes(chords)
                                    self.cycle_through_images()
                        else:
                            self.message.config(text=note + " is being played. It is not the root note")

            if self.stop_video_thread is True:
                self.video_cap.release()
                return
            else:
                self.root.after(10, self.video_record)
        except RuntimeError:
            print("RuntimeError")

    def onClose(self):
        self.root.quit()

if __name__ == '__main__':
    multiprocessing.set_start_method("spawn")
    skin_color_histogram = np.load("skin_color_histogram.npy")
    guitar_guide = GuitarGuide(skin_color_histogram)
    guitar_guide.root.mainloop()
