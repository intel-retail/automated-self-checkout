#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# Download media
./download_sample_videos.sh

PLATFORM=$1
CPU_ONLY=$2

if [ "$PLATFORM" == "" ]
then
    PLATFORM="core"
fi

if [ "$CPU_ONLY" == "" ]
then
    CPU_ONLY=0
fi

sudo rm -rf results || true
sudo rm -rf platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_full/  || true
sudo rm -rf platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_yolov5_classification/  || true
sudo rm -rf platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_yolov5/  || true
sudo rm -rf platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_file_full/ || true
sudo rm -rf platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_stream_density/ || true

# Camera simulator full pipeline
sudo CPU_ONLY=$CPU_ONLY ./benchmark.sh --pipelines 1 --logdir platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_full/data --init_duration 30 --duration 60 --platform $PLATFORM --inputsrc rtsp://127.0.0.1:8554/camera_0
# consolidate results
make consolidate ROOT_DIRECTORY=platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_full


# Camera simulator Yolov5 and classification only
sudo CPU_ONLY=$CPU_ONLY  ./benchmark.sh --pipelines 1 --logdir platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_yolov5_classification/data --init_duration 30 --duration 60 --platform $PLATFORM --inputsrc rtsp://127.0.0.1:8554/camera_0 --ocr_disabled --barcode_disabled
# consolidate results
make consolidate ROOT_DIRECTORY=platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_yolov5_classification


# Camera simulator yolov5 only
sudo CPU_ONLY=$CPU_ONLY ./benchmark.sh --pipelines 1 --logdir platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_yolov5/data --init_duration 30 --duration 60 --platform $PLATFORM --inputsrc rtsp://127.0.0.1:8554/camera_0 --ocr_disabled --barcode_disabled --classification_disabled
# consolidate results
make consolidate ROOT_DIRECTORY=platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_yolov5


# File full pipeline
sudo CPU_ONLY=$CPU_ONLY ./benchmark.sh --pipelines 1 --logdir platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_file_full/data --init_duration 5 --duration 20 --platform $PLATFORM --inputsrc file:coca-cola-4465029-3840-15-bench.mp4
# consolidate results
make consolidate ROOT_DIRECTORY=platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_file_full


# Stream density
sudo CPU_ONLY=$CPU_ONLY ./benchmark.sh --stream_density 60 --logdir platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_stream_density/data --init_duration 30 --duration 60 --platform $PLATFORM --inputsrc rtsp://127.0.0.1:8554/camera_0
