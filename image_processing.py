import cv2
import numpy as np
import imutils
# Create a VideoCapture object and read from input file
# If the input is the camera, pass 0 instead of the video file name
cam = cv2.VideoCapture(0)
cv2.namedWindow("Capture")

cv2.namedWindow("Main")

while True:

    # Capture frame-by-frame. If the frame is read correctly, then ret is true
    ret, frame = cam.read()
    cv2.imshow("Main", frame)
    if not ret:
        break

    # waits for 1ms for user to provide input
    k = cv2.waitKey(1)

    if k % 256 == 27:
        # ESC pressed
        print("Escape hit, closing...")
        break
    elif k % 256 == 32:
        # SPACE pressed

        back = cv2.imread('background.jpg')
        img = frame.copy()

        # igray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        # backgray = cv2.cvtColor(back, cv2.COLOR_BGR2GRAY)
        # sub = igray - backgray
        # cv2.imshow("DSUB",sub)
        # ret,t1= cv2.threshold(sub,50,255,cv2.THRESH_BINARY)
        # cv2.imshow("thresholdadsdfas", t1)
        #
        # bit_and = cv2.bitwise_and(t1, igray)
        # cv2.imshow("DSSDSDS",bit_and)


        height, width, channels = img.shape

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        edges = cv2.Canny(gray, 150, 250)
        cv2.imshow("EDGE BITH", edges)

        lines = cv2.HoughLinesP(edges, 1, np.pi/180, 150, maxLineGap=150, minLineLength=600)

        hough_1 = img.copy()
        for line in lines:
            x1, y1, x2, y2 = line[0]
            cv2.line(hough_1, (x1, y1), (x2, y2), (0, 255, 0), 3)
        cv2.imshow("HOUGH1", hough_1)



        print(len(lines))
        lines
        gradients = []
        for line in lines:
            x1, y1, x2, y2 = line[0]
            gradients.append((y1 - y2) / (x1 - x2))



        median_gradient = np.median(gradients)

        gradients

        lines_filtered = []

        print("EW")
        print(median_gradient)
        for i in range(len(gradients)):
            if (median_gradient < 0):
                if gradients[i] >= (1.5 * median_gradient) and gradients[i] <= (0.5 * median_gradient):
                    lines_filtered.append(lines[i])
            else:
                if gradients[i] <= (1.5 * median_gradient) and gradients[i] >= (0.5 * median_gradient):
                    lines_filtered.append(lines[i])


        hough_2 = img.copy()
        for line in lines_filtered:
            x1, y1, x2, y2 = line[0]
            print("LINE ka gradient ", (y2 - y1) / (x2 - x1))
            cv2.line(hough_2, (x1, y1), (x2, y2), (0, 255, 0), 3)

        cv2.imshow("Hough2", hough_2)

        hough_3 = img.copy()
        maxyvalues = []
        for line in lines_filtered:
        	x1, y1, x2, y2 = line[0]
        	maxyvalues.append(max(y1, y2))

        percentiles = np.percentile(maxyvalues, [20, 50, 75])
        print(percentiles)

        IQ_range = percentiles[2] - percentiles[0]

        y_ULimit = -1

        y_LLimit = 99999

        for line in lines_filtered:
        	x1, y1, x2, y2 = line[0]

        	max_value = max(y1, y2)
        	if max_value > y_ULimit and max_value < percentiles[2] + 3 * IQ_range:
        		uLine = line
        		y_ULimit = max_value

        	if max_value < y_LLimit and max_value > percentiles[0] - 3 * IQ_range :
        		lLine = line
        		y_LLimit = max_value

        x1, y1, x2, y2 = uLine[0]
        cv2.line(hough_3, (x1, y1), (x2, y2), (0, 255, 0), 3)

        x3, y3, x4, y4 = lLine[0]
        cv2.line(hough_3, (x3, y3), (x4, y4), (0, 255, 0), 3)

        cv2.imshow("Hough3", hough_3)
        #
        # print shape of mask
        mask = np.zeros((height, width), dtype=np.uint8)
        points = np.array([[[x1, y1], [x2, y2], [x4, y4], [x3, y3]]])
        cv2.fillPoly(mask, points, (255))
        cv2.imshow("mask", mask)

        _, contours, _ = cv2.findContours(mask, 1, 1)

        cnt = contours[0]
        # crop normal rectangle
        # points = np.array([[[100,100],[300,100],[300,200],[100,200]]])
        # rect = cv2.boundingRect(points)
        # x,y,w,h = rect
        # cropped = img[y:y+h, x:x+w].copy()

        rect = cv2.minAreaRect(cnt)
        box = cv2.boxPoints(rect)
        box = np.int0(box)
        #cv2.drawContours(img,[box],0,(0,0,255),2)
        cv2.imshow("LOL",img)


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
            angle+=90
            rotated = True

        center = (int((x1+x2)/2), int((y1+y2)/2))
        size = (int(mult*(x2-x1)),int(mult*(y2-y1)))

        M = cv2.getRotationMatrix2D((size[0]/2, size[1]/2), angle, 1.0)

        cropped = cv2.getRectSubPix(img_box, size, center)
        cropped = cv2.warpAffine(cropped, M, size)

        croppedW = W if not rotated else H
        croppedH = H if not rotated else W

        croppedRotated = cv2.getRectSubPix(cropped, (int(croppedW*mult), int(croppedH*mult)), (size[0]/2, size[1]/2))

        cv2.imshow("CROPPEDROTATED", croppedRotated)

        imgHSV= cv2.cvtColor(croppedRotated,cv2.COLOR_BGR2HSV)
        cv2.imshow("imgHSAV", imgHSV)

        grayed = cv2.cvtColor(croppedRotated.copy(), cv2.COLOR_BGR2GRAY)
        sobelx = cv2.Sobel(grayed, -1, 1, 0, ksize=1)
        cv2.imshow("sobelx", sobelx)

        ret,thresh1 = cv2.threshold(sobelx,20,255,cv2.THRESH_BINARY)

        cv2.imshow("thres", thresh1)

        kernel = np.ones((5,5),np.uint8)


        # median = cv2.medianBlur(thresh1, 5)
        # cv2.imshow("median", median)
        # closing = cv2.morphologyEx(median, cv2.MORPH_CLOSE, kernel)
        # cv2.imshow("closing", closing)
        # crop
        #img_croped = crop_minAreaRect(img, rect)
        # cv2.imshow("cropped", img_croped)
        # print(img.shape)


        lines = cv2.HoughLinesP(thresh1, 1, np.pi, 50, maxLineGap=8, minLineLength=10)
        hough_4 = croppedRotated.copy()
        for line in lines:
            x1, y1, x2, y2 = line[0]
            cv2.line(hough_4, (x1, y1), (x2, y2), (0, 255, 0), 1)

        cv2.imshow("Hough4", hough_4)

        min_x = 99999
        max_x = 0
        for line in lines:
            x1, _, _, _ = line[0]
            if x1 < min_x:
                min_x = x1
            if x1 > max_x:
                max_x = x1

        print(max_x)
        print(min_x)

        roi = croppedRotated[0:,min_x:max_x]
        cv2.imshow('ROI',roi)

        imgray = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
        cv2.imshow("GRY", imgray)
        imgray = cv2.GaussianBlur(imgray, (5, 5), 0)
        cv2.imshow("LALLALAL", imgray)
        # threshold the image, then perform a series of erosions +
        # dilations to remove any small regions of noise

        ret, thresh = cv2.threshold(imgray, 127, 255, 0)
        # threshold the image, then perform a series of erosions +
        # dilations to remove any small regions of noise
        thresh = cv2.erode(thresh, None, iterations=2)
        thresh = cv2.dilate(thresh, None, iterations=2)

        cv2.imshow("DFS",thresh)

        cnts = cv2.findContours(thresh.copy(), cv2.RETR_EXTERNAL,
        	cv2.CHAIN_APPROX_SIMPLE)
        cnts = imutils.grab_contours(cnts)

        c = max(cnts, key=cv2.contourArea)
        # determine the most extreme points along the contour
        extLeft = tuple(c[c[:, :, 0].argmin()][0])
        extRight = tuple(c[c[:, :, 0].argmax()][0])
        extTop = tuple(c[c[:, :, 1].argmin()][0])
        extBot = tuple(c[c[:, :, 1].argmax()][0])

        cv2.drawContours(roi, [c], -1, (0, 255, 255), 2)
        cv2.circle(roi, extLeft, 8, (0, 0, 255), -1)
        cv2.circle(roi, extRight, 8, (0, 255, 0), -1)
        cv2.circle(roi, extTop, 8, (255, 0, 0), -1)
        cv2.circle(roi, extBot, 8, (255, 255, 0), -1)



        # im2, contours, hierarchy = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_NONE)
        # cnt = contours[0]
        # cv2.drawContours(roi, [cnt], 0, (0,255,0), 3)
        # cv2.drawContours(roi, contours, -1, (0,255,0), 3)

        cv2.imshow("roi updare", roi)

cam.release()
cv2.destroyAllWindows()
