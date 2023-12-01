#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# initial setup
(
    cd ..
    make clean-all
    sleep 3
    make build-dlstreamer
)

# build benchmark Docker images:
make

# Download media
./download_sample_videos.sh

PLATFORM=$1
CPU_ONLY=$2

if [ -z "$PLATFORM" ]
then
    PLATFORM="core"
fi

if [ -z "$CPU_ONLY" ]
then
    CPU_ONLY=0
fi

sudo rm -rf results || true
sudo rm -rf platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_gst/  || true
sudo rm -rf platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_capi_yolov5_ensemble/  || true
sudo rm -rf platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_object_detection/  || true
sudo rm -rf platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_stream_density/ || true

# Note: all of benchmarking pipelines are run with RENDER_MODE=0 for better performance without spending extra resources for rendering
# Camera simulator full pipeline
# shell check has false postive on SC2097 and SC2098 as it doesn't detect -E flag which is inhereted the envs into subprocess; hence disable here
# shellcheck disable=SC2097,SC2098
PIPELINE_PROFILE="gst" CPU_ONLY="$CPU_ONLY" RENDER_MODE=0 sudo -E ./benchmark.sh --pipelines 1 --logdir platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_gst/data --init_duration 30 --duration 60 --platform "$PLATFORM" --inputsrc rtsp://127.0.0.1:8554/camera_0
# consolidate results
make consolidate ROOT_DIRECTORY=platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_te_smoke_test_camera_simulator_gst

# Camera simulator for capi_yolov5_ensemble
# shell check has false postive on SC2097 and SC2098 as it doesn't detect -E flag which is inhereted the envs into subprocess; hence disable here
# shellcheck disable=SC2097,SC2098
PIPELINE_PROFILE="capi_yolov5_ensemble" CPU_ONLY=$CPU_ONLY RENDER_MODE=0 sudo -E ./benchmark.sh --pipelines 1 --logdir platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_capi_yolov5_ensemble/data --init_duration 30 --duration 60 --platform "$PLATFORM" --inputsrc rtsp://127.0.0.1:8554/camera_0
# consolidate results
make consolidate ROOT_DIRECTORY=platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_capi_yolov5_ensemble

# Camera simulator yolov5 only
# shell check has false postive on SC2097 and SC2098 as it doesn't detect -E flag which is inhereted the envs into subprocess; hence disable here
# shellcheck disable=SC2097,SC2098
PIPELINE_PROFILE="object_detection" CPU_ONLY=$CPU_ONLY RENDER_MODE=0 sudo -E ./benchmark.sh --pipelines 1 --logdir platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_object_detection/data --init_duration 30 --duration 60 --platform "$PLATFORM" --inputsrc rtsp://127.0.0.1:8554/camera_0
# consolidate results
make consolidate ROOT_DIRECTORY=platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_camera_simulator_object_detection

# Stream density for object detection
# shell check has false postive on SC2097 and SC2098 as it doesn't detect -E flag which is inhereted the envs into subprocess; hence disable here
# shellcheck disable=SC2097,SC2098
PIPELINE_PROFILE="object_detection" CPU_ONLY=$CPU_ONLY RENDER_MODE=0 sudo -E ./benchmark.sh --stream_density 60 --logdir platform_"$PLATFORM"_cpuonly_"$CPU_ONLY"_smoke_test_stream_density/data --init_duration 30 --duration 60 --platform "$PLATFORM" --inputsrc rtsp://127.0.0.1:8554/camera_0
