#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# Download media
./download_sample_videos.sh

sudo rm -rf results || true
sudo rm -rf smoke_test_camera_simulator_full/  || true
sudo rm -rf smoke_test_camera_simulator_yolov5/  || true
sudo rm -rf smoke_test_file_full/ || true
sudo rm -rf smoke_test_stream_density/ || true

# Camera simulator full pipeline
sudo ./benchmark.sh --pipelines 1 --logdir smoke_test_camera_simulator_full/data --init_duration 30 --duration 60 --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
# consolidate results
make consolidate ROOT_DIRECTORY=smoke_test_camera_simulator_full

# Camera simulator yolov5 only
sudo ./benchmark.sh --pipelines 1 --logdir smoke_test_camera_simulator_yolov5/data --init_duration 30 --duration 60 --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --ocr_disabled --barcode_disabled --classification_disabled
# consolidate results
make consolidate ROOT_DIRECTORY=smoke_test_camera_simulator_yolov5

# File full pipeline
sudo ./benchmark.sh --pipelines 1 --logdir smoke_test_file_full/data --init_duration 5 --duration 20 --platform core --inputsrc file:coca-cola-4465029-3840-15-bench.mp4
# consolidate results
make consolidate ROOT_DIRECTORY=smoke_test_file_full

# Stream density
sudo ./benchmark.sh --stream_density 14.90 --logdir smoke_test_stream_density/data --init_duration 30 --duration 60 --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
