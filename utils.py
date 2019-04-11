import cv2
import numpy as np
import struct
from math import log2, pow
import math
import json
import re
from scipy.signal import blackmanharris, fftconvolve
from numpy import argmax, sqrt, mean, diff, log
from matplotlib.mlab import find

js = open('chords.json').read()
chord_data = json.loads(js)

js = open('mappings.json').read()
pixel_data = json.loads(js)
fretboard_img =  cv2.imread('images/fretboard.jpg')

def parabolic(f, x):
    xv = 1/2. * (f[x-1] - f[x+1]) / (f[x-1] - 2 * f[x] + f[x+1]) + x
    yv = f[x] - 1/4. * (f[x-1] - f[x+1]) * (xv - x)
    return (xv, yv)

def freq_from_autocorr(raw_data_signal, fs=44100):
    corr = fftconvolve(raw_data_signal, raw_data_signal[::-1], mode='full')
    corr = corr[int(len(corr)/2):]
    d = diff(corr)
    start = find(d > 0)[0]
    peak = argmax(corr[start:]) + start
    px, py = parabolic(corr, peak)
    return fs / px

def get_trailing_number(s):
    m = re.search(r'\d+$', s)
    return int(m.group()) if m else None

def find_chords(type, string, fret):
    chords_to_show = []
    for chord in chord_data[type]:
        if chord['root-position'][0] is string and chord['root-position'][1] is fret:
            chords_to_show.append(chord)
    return chords_to_show

def image_notes(chords_to_show):
    images_array = []
    for j in range(len(chords_to_show)):
        img =  fretboard_img.copy()
        for i in range(len(chords_to_show[j]['notes'])):
            note = chords_to_show[j]['notes'][i]
            img = cv2.circle(img, tuple(pixel_data[str(note[0])+str(note[1])]), 40, (0, 255, 0), -1)
        root_note = chords_to_show[0]['root-position']
        img = cv2.circle(img, tuple(pixel_data[str(root_note[0])+str(root_note[1])]), 40, (255, 0, 0), -1)
        img = cv2.resize(img, (1320, 400))
        images_array.append(img)

    return images_array

def pitch_to_note(freq):
    # variables defined for converting pitch to note
    A4 = 440
    C0 = A4 * pow(2, -4.75)
    name = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    h = round(12 * log2(freq / C0))
    octave = int(h // 12)
    n = int(h % 12)
    return name[n] + str(octave)

def get_fretboard_position(pitch, result_from_cv_algo):
    fret_lengths = [0, 1.431, 2.782, 4.057,
        5.261, 6.397, 7.469, 8.481,
        9.436, 10.338, 11.189, 11.992,
        12.75, 13.466, 14.141, 14.779,
        15.38, 15.948, 16.483, 16.99,
        17.468, 17.919, 18.344]
    fret_lengths_ratios = [0.0, 7.8, 15.17, 22.12, 28.68, 34.87, 40.72, 46.23, 51.44, 56.36, 61.0, 65.37, 69.51, 73.41, 77.09, 80.57, 83.84, 86.94, 89.85, 92.62, 95.22, 97.68, 100.0]
    note_posible_combinations = {
        'E2': [(6, 0)],
        'F2': [(6, 1)],
        'F#2': [(6, 2)],
        'G2': [(6, 3)],
        'G#2': [(6, 4)],
        'A2': [(6, 5), (5, 0)],
        'A#2': [(6, 6), (5, 1)],
        'B2': [(7, 6), (5, 2)],

        'C3': [(6,8), (5,3)],
        'C#3': [(6,9), (5,4)],
        'D3': [(6,10), (5,5), (4,0)],
        'D#3': [(6,11), (5,6), (4,1)],
        'E3': [(6,12), (5,7), (4,2)],
        'F3': [(6,13), (5,8), (4,3)],
        'F#3': [(6,14), (5,9), (4,4)],
        'G3': [(6,15), (5,10), (4,5), (3,0)],
        'G#3': [(6,16), (5,11), (4,6), (3,1)],
        'A3': [(6,17), (5,12), (4,7), (3,2)],
        'A#3': [(6,18), (5,13), (4,8), (3,3)],
        'B3': [(6,19), (5,14), (4,9), (3,4), (2,0)],

        'C4': [(6,20), (5,15), (4,10), (3,5), (2,1)],
        'C#4': [(6,21), (5,16), (4,11), (3,6), (2,2)],
        'D4': [(6,22), (5,17), (4,12), (3,7), (2,3)],
        'D#4': [(5,18), (4,13), (3,8), (2,4)],
        'E4': [(5,19), (4,14), (3,9), (2,5), (1,0)],
        'F4': [(5,20), (4,15), (3,10), (2,6), (1,1)],
        'F#4': [(5,21), (4,16), (3,11), (2,7), (1,2)],
        'G4': [(5,22), (4,17), (3,12), (2,8), (1,3)],
        'G#4': [(4,18), (3,13), (2,9), (1,4)],
        'A4': [(4,19), (3,14), (2,10), (1,5)],
        'A#4': [(4,20), (3,15), (2,11), (1,6)],
        'B4': [(4,21), (3,16), (2,12), (1,7)],

        'C5': [(4,22), (3,17), (2,13), (1,8)],
        'C#5': [(3,18), (2,14), (1,9)],
        'D5': [(3,19), (2,15), (1,10)],
        'D#5': [(3,20), (2,16), (1,11)],
        'E5': [(3,21), (2,17), (1,12)],
        'F5': [(3,22), (2,18), (1,13)],
        'F#5': [(2,19), (1,14)],
        'G5': [(2,20), (1,15)],
        'G#5': [(2,21), (1,16)],
        'A5': [(2,22), (1,17)],
        'A#5': [(1,18)],
        'B5': [(1,19)],

        'C6': [(1,20)],
        'C#6': [(1,21)],
        'D6': [(1,22)]
    }

    differences = []
    for (_, y) in note_posible_combinations[pitch]:
        differences.append(abs(result_from_cv_algo - fret_lengths_ratios[y]))

    index = np.argmin(np.array(differences))
    return note_posible_combinations[pitch][index]

def image_processing(img, note, skin_color_histogram):
    # part 1: Hough Lines Detection
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 100, 200)

    lines = None
    lines = cv2.HoughLinesP(edges, 1, np.pi/180, 80, maxLineGap=60, minLineLength=700)
    if lines is not None and len(lines) >= 7:
        hough_1 = img.copy()
        for line in lines:
            x1, y1, x2, y2 = line[0]
            cv2.line(hough_1, (x1, y1), (x2, y2), (0, 255, 0), 3)
    else:
        # Flag message returned because less than 7 Hough Lines were detected
        print("Hough Line not being Detected")
        return (-1, -1);

    # cv2.imshow("Hough 1", hough_1)
    outline = img.copy()
    # part 2: Get the top and bottom most line using functions of all the lines
    sum_y = []
    for line in lines:
        x1, y1, x2, y2 = line[0]
        points = [(x1,y1),(x2,y2)]
        m = (y2 - y1) / (x2 - x1)
        c = y1 - (m * x1)
        y_value = m * 640 + c
        sum_y.append(y_value)

    upper_line = lines[sum_y.index(max(sum_y))]
    lower_line = lines[sum_y.index(min(sum_y))]

    x1, y1, x2, y2 = upper_line[0]
    x3, y3, x4, y4 = lower_line[0]

    cv2.line(outline, (x1, y1), (x2, y2), (0, 255, 0), 3)
    cv2.line(outline, (x3, y3), (x4, y4), (0, 255, 0), 3)
    # cv2.imshow("outline", outline)

    # part 3: crop and rotate
    (height, width, _) = img.shape
    mask = np.zeros((height, width), dtype=np.uint8)
    points = np.array([[[x1, y1], [x2, y2], [x4, y4], [x3, y3]]])
    cv2.fillPoly(mask, points, (255))

    _, contours, _ = cv2.findContours(mask, 1, 1)
    cnt = contours[0]

    rect = cv2.minAreaRect(cnt)
    box = cv2.boxPoints(rect)
    box = np.int0(box)

    mult = 1.15
    img_box = img.copy()
    W = rect[1][0]
    H = rect[1][1]

    Xs = [i[0] for i in box]
    Ys = [i[1] for i in box]
    x1 = min(Xs)
    x2 = max(Xs)
    y1 = min(Ys)
    y2 = max(Ys)

    rotated = False
    angle = rect[2]

    if angle < -45:
        angle += 90
        rotated = True

    center = (int((x1+x2)/2), int((y1+y2)/2))
    size = (int(mult*(x2-x1)),int(mult*(y2-y1)))

    M = cv2.getRotationMatrix2D((size[0]/2, size[1]/2), angle, 1.0)

    cropped = cv2.getRectSubPix(img_box, size, center)
    cropped = cv2.warpAffine(cropped, M, size)

    cropped_w = W if not rotated else H
    cropped_h = H if not rotated else W

    cropped_and_rotated = cv2.getRectSubPix(cropped, (int(cropped_w * mult), int(cropped_h * mult)), (size[0]/2, size[1]/2))

    # part 4: Vertical Hough Line Transform to get only the Fretboard
    # and part 5: crop only fretboard out based on hough Transform
    gray = cv2.cvtColor(cropped_and_rotated, cv2.COLOR_BGR2GRAY)
    sobelx = cv2.Sobel(gray, -1, 1, 0, ksize=3)
    ret, thresh1 = cv2.threshold(sobelx, 80, 255,cv2.THRESH_BINARY)
    kernel = np.ones((5,5), np.uint8)
    median = cv2.medianBlur(thresh1, 1)

    min_x = cropped_and_rotated.shape[1] / 2
    max_x = cropped_and_rotated.shape[1] / 2
    lines = cv2.HoughLines(median, 1, np.pi/180, 30)

    if lines is not None and len(lines) >= 10:
        hough_2 = cropped_and_rotated.copy()
        for line in lines:
            rho, theta = line[0]
            if -0.1 < theta and theta < 0.1:
                a = np.cos(theta)
                b = np.sin(theta)
                x0 = a*rho
                y0 = b*rho

                x1 = int(x0 + 1000*(-b))
                y1 = int(y0 + 1000*(a))
                x2 = int(x0 - 1000*(-b))
                y2 = int(y0 - 1000*(a))

                points = [(x1,y1),(x2,y2)]
                diff_x = x2 - x1
                if diff_x is 0:
                    x_intercept = x1
                else:
                    m = (y2 - y1) / (x2 - x1)
                    c = y1 - (m * x1)
                    x_intercept = ((cropped_and_rotated.shape[0]/2) - c) / m

                if min_x >= x_intercept:
                    min_x = x_intercept
                if max_x <= x_intercept:
                    max_x = x_intercept
                cv2.line(hough_2, (x1,y1), (x2,y2), (0,0,255), 2)
    else:
        # Flag message returned because less than 10 Hough Vertical Lines were detected
        print("Hough Line Vertical not being Detected")
        return (-1, -1);

    roi = cropped_and_rotated[0:,int(min_x):int(max_x)]

    # part 6: Detect the skin color on the ROI using the skin colour Histogram
    frame_hsv = cv2.cvtColor(roi, cv2.COLOR_BGR2HSV)
    dst = cv2.calcBackProject([frame_hsv], [0,1], skin_color_histogram, [0,180,0,256], 1)
    disc = cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(5,5))
    cv2.filter2D(dst, -1, disc, dst)
    ret, thresh = cv2.threshold(dst, 100, 255, 0)

    _, cnts, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    c = max(cnts, key=cv2.contourArea)
    extLeft = tuple(c[c[:, :, 0].argmin()][0])
    extRight = tuple(c[c[:, :, 0].argmax()][0])
    extBot = tuple(c[c[:, :, 1].argmax()][0])
    extTop = tuple(c[c[:, :, 1].argmin()][0])

    result_from_cv_algo = (1 - (extTop[0] / roi.shape[1])) * 100
    (string, fret) = get_fretboard_position(note, result_from_cv_algo)
    return (string, fret)
