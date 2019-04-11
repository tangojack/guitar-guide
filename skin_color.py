import cv2
import numpy as np

if __name__ == "__main__":
    video_cap = cv2.VideoCapture(0)

    while True:
      ret, video_frame = video_cap.read()
      cv2.imshow('video_frame', video_frame)

      # If the key pressed is space
      if cv2.waitKey(1) is 32:
         # Select ROI
         r = cv2.selectROI("Image", video_frame, False, False)
         roi = video_frame[int(r[1]):int(r[1]+r[3]), int(r[0]):int(r[0]+r[2])]
         roi_hsv = cv2.cvtColor(roi, cv2.COLOR_BGR2HSV)

         # Creating a Histogram of the HSV Colors
         roi_hist = cv2.calcHist([roi_hsv], [0, 1], None, [180, 256], [0, 180, 0, 256])

         ### Documentation: Uncomment and take a screenshot of the image for documentation
         cv2.normalize(roi_hist, roi_hist, 0, 255, cv2.NORM_MINMAX)
         frame_hsv = cv2.cvtColor(video_frame, cv2.COLOR_BGR2HSV)
         dst = cv2.calcBackProject([frame_hsv], [0,1], roi_hist, [0,180,0,256], 1)
         disc = cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(5,5))
         cv2.filter2D(dst, -1, disc, dst)

         ret, thresh = cv2.threshold(dst, 100, 255, 0)
         thresh = cv2.merge((thresh, thresh, thresh))
         res = cv2.bitwise_and(video_frame, thresh)
         res = np.vstack((video_frame, thresh, res))
         cv2.imshow("Result", res)

         break

    print(type(roi_hist))
    print(roi_hist)
    np.save("data/skin_color_histogram", roi_hist)

    video_cap.release()
    cv2.waitKey(0)
    cv2.destroyAllWindows()
