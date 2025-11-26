#!/bin/bash

VIDEO_DIR="/home/intel/sachin/streamer"
VIDEO1="$VIDEO_DIR/obj_classification-1920-15-bench.mp4"

# download mp4 if missing
if [ ! -f "$VIDEO1" ]; then
    mkdir -p "$VIDEO_DIR"
    wget -O "$VIDEO1" "https://www.pexels.com/download/video/6891009"
fi

if [ "$PIPELINE_SCRIPT" = "obj_detection_age_prediction.sh" ]; then
    echo "Age prediction is enabled."
    ffmpeg -nostdin -re -stream_loop -1 -i "$VIDEO_DIR/age_prediction-1920-15-bench.mp4" -c copy -f rtsp -rtsp_transport tcp rtsp://localhost:8554/camera_1 &
    ffmpeg -nostdin -re -stream_loop -1 -i "$VIDEO_DIR/obj_classification-1920-25-bench.mp4" -c copy -f rtsp -rtsp_transport tcp rtsp://localhost:8554/camera_2
else
    ffmpeg -nostdin -re -stream_loop -1 -i "$VIDEO1" -c copy -f rtsp -rtsp_transport tcp rtsp://localhost:8554/camera_0
fi
