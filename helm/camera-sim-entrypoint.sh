#!/bin/sh
#
# Copyright (C) 2025 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

if [ ! -f /home/pipeline-server/sample-media/coca-cola-4465029-1920-15-bench.mp4 ]; then
    mkdir -p /home/pipeline-server/sample-media
    wget -O /home/pipeline-server/sample-media/coca-cola-4465029-1920-15-bench.mp4 https://www.pexels.com/download/video/4465029
fi

ffmpeg -nostdin -re -stream_loop -1 -i /home/pipeline-server/sample-media/coca-cola-4465029-1920-15-bench.mp4 -c copy -f rtsp -rtsp_transport tcp rtsp://camera-simulator:8554/camera_0