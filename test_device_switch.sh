#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

make clean-all
make build-profile-launcher
(
	cd ./benchmark-scripts
	./download_sample_videos.sh
)
make run-camera-simulator
sleep 5
PIPELINE_PROFILE="classification" RENDER_MODE=1 sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
sleep 20
PIPELINE_PROFILE="classification" DEVICE="GPU.0" RENDER_MODE=1 sudo -E ./run.sh --platform dgpu.0 --inputsrc rtsp://127.0.0.1:8554/camera_0
sleep 20

# verify that config json for both ovms server instances exist
if [ -f ./configs/opencv-ovms/models/2022/config_ovms-server0.json ]
then
	echo "PASSED: OVMS server config_ovms-server0.json exists for the instance of Docker ovms-server0"
else
	echo "FAILED: OVMS server config_ovms-server0.json does NOT exist for the instance of Docker ovms-server0"
fi

if [ -f ./configs/opencv-ovms/models/2022/config_ovms-server0.json ]
then
	echo "PASSED: OVMS server config_ovms-server1.json exists for the instance of Docker ovms-server1"
else
	echo "FAILED: OVMS server config_ovms-server1.json does NOT exist for the instance of Docker ovms-server1"
fi

docker logs ovms-server0 | grep "CPU"

docker logs ovms-server1 | grep "GPU"

sleep 5
# clean up
make clean-ovms
