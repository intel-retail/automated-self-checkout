#!/bin/bash
#
# Copyright (C) 2025 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

if [ ! -f /home/pipeline-server/sample-media/obj_classification-1920-15-bench.mp4 ]; then
   mkdir -p /home/pipeline-server/sample-media
   wget -O /home/pipeline-server/sample-media/obj_classification-1920-15-bench.mp4 https://www.pexels.com/download/video/6891009
fi

if [ "${PIPELINE_SCRIPT}" = "obj_detection_age_prediction.sh" ]; then
   echo "Age prediction is enabled."
   ffmpeg -nostdin -re -stream_loop -1 -i /home/pipeline-server/sample-media/age_prediction-1920-15-bench.mp4 -c copy -f rtsp -rtsp_transport tcp rtsp://localhost:8554/camera_1 &
   ffmpeg -nostdin -re -stream_loop -1 -i /home/pipeline-server/sample-media/obj_classification-1920-25-bench.mp4 -c copy -f rtsp -rtsp_transport tcp rtsp://localhost:8554/camera_2
else
   ffmpeg -nostdin -re -stream_loop -1 -i /home/pipeline-server/sample-media/obj_classification-1920-15-bench.mp4 -c copy -f rtsp -rtsp_transport tcp rtsp://localhost:8554/camera_0
fi

#add frame late in ffmpeg cmd