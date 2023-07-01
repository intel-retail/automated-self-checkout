# docker run --user root -e "DISPLAY=$DISPLAY" -v "$HOME/.Xauthority:/root/.Xauthority:ro" --privileged  -v /home/intel/projects/automated-self-checkout/configs/opencv-ovms/scripts/:/scripts -v /tmp/.X11-unix:/tmp/.X11-unix -it ovms-client:latest bash
# xhost +local:root
import cv2
import os

RTSP_URL = 'rtsp://192.168.0.246:8554/camera_0'

os.environ['OPENCV_FFMPEG_CAPTURE_OPTIONS'] = 'rtsp_transport;udp'

cap = cv2.VideoCapture(RTSP_URL, cv2.CAP_FFMPEG)

if not cap.isOpened():
    print('Cannot open RTSP stream')
    exit(-1)

while True:
    _, frame = cap.read()
    width = 608
    height = 608
    img = cv2.resize(frame, (width, height))
    # img = img.transpose(2,0,1).reshape(1,3,height,width)
    cv2.imshow('RTSP stream', img)

    if cv2.waitKey(1) == 27:
        break

cap.release()
cv2.destroyAllWindows()