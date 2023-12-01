#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

SERVER_CONTAINER_NAME="ovms-server"
# clean up exited containers
docker rm $(docker ps -a -f name=$SERVER_CONTAINER_NAME -f status=exited -q)

export GST_DEBUG=0

source benchmark-scripts/get-gpu-info.sh

if [ -z "$PLATFORM" ] || [ -z "$INPUTSRC" ]
then
	source get-options.sh "$@"
fi

cl_cache_dir=`pwd`/.cl-cache
echo "CLCACHE: $cl_cache_dir"


if [ $HAS_FLEX_140 == 1 ] || [ $HAS_FLEX_170 == 1 ] || [ $HAS_ARC == 1 ] 
then
    echo "OCR device defaulting to dGPU"
    OCR_DEVICE=GPU
fi

if [ ! -z "$CONTAINER_IMAGE_OVERRIDE" ]
then
	echo "Using container image override $CONTAINER_IMAGE_OVERRIDE"
	TAG=$CONTAINER_IMAGE_OVERRIDE
fi

gstDockerImages="dlstreamer:dev"
re='^[0-9]+$'
if grep -q "video" <<< "$INPUTSRC"; then
	echo "assume video device..."
	# v4l2src /dev/video*
	# TODO need to pass stream info
	TARGET_USB_DEVICE="--device=$INPUTSRC"
elif [[ "$INPUTSRC" =~ $re ]]; then
	echo "assume realsense device..."
	cameras=`ls /dev/vid* | while read line; do echo "--device=$line"; done`
	TARGET_GPU_DEVICE=$TARGET_GPU_DEVICE" "$cameras
	gstDockerImages="dlstreamer:realsense"
else
	echo "$INPUTSRC"
fi

if [ "$PIPELINE_PROFILE" == "gst" ]
then
	# modify gst profile DockerImage accordingly based on the inputsrc is RealSense camera or not

	docker run --rm -v "${PWD}":/workdir mikefarah/yq -i e '.OvmsClient.DockerLauncher.DockerImage |= "'"$gstDockerImages"'"' \
		/workdir/configs/opencv-ovms/cmd_client/res/gst/configuration.yaml
fi

#pipeline script is configured from configuration.yaml in opencv-ovms/cmd_client/res folder

# Set RENDER_MODE=1 for demo purposes only
if [ "$RENDER_MODE" == 1 ]
then
	xhost +local:docker
fi

#echo "DEBUG: $TARGET_GPU_DEVICE $PLATFORM $HAS_FLEX_140"
if [ "$PLATFORM" == "dgpu" ] && [ $HAS_FLEX_140 == 1 ]
then
	if [ "$STREAM_DENSITY_MODE" == 1 ]; then
		AUTO_SCALE_FLEX_140=2
	else
		# allow workload to manage autoscaling
		AUTO_SCALE_FLEX_140=1
	fi
fi

# make sure models are downloaded or existing:
./download_models/getModels.sh

# make sure sample image is downloaded or existing:
./configs/opencv-ovms/scripts/image_download.sh

# devices supported CPU, GPU, GPU.x, AUTO, MULTI:GPU,CPU
DEVICE="${DEVICE:="CPU"}"

# PIPELINE_PROFILE is the environment variable to choose which type of pipelines to run with
# eg. grpc_python, grpc_cgo_binding, ... etc
# one example to run with this pipeline profile on the command line is like:
# PIPELINE_PROFILE="grpc_python" sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
PIPELINE_PROFILE="${PIPELINE_PROFILE:=grpc_python}"
echo "starting profile-launcher with pipeline profile: $PIPELINE_PROFILE ..."
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
cameras="$cameras" \
TARGET_USB_DEVICE="$TARGET_USB_DEVICE" \
TARGET_GPU_DEVICE="$TARGET_GPU_DEVICE" \
DEVICE="$DEVICE" \
MQTT="$MQTT" \
RENDER_MODE=$RENDER_MODE \
DISPLAY=$DISPLAY \
cl_cache_dir=$cl_cache_dir \
RUN_PATH=`pwd` \
PLATFORM=$PLATFORM \
BARCODE_RECLASSIFY_INTERVAL=$BARCODE_INTERVAL \
OCR_RECLASSIFY_INTERVAL=$OCR_INTERVAL \
OCR_DEVICE=$OCR_DEVICE \
LOG_LEVEL=$LOG_LEVEL \
LOW_POWER="$LOW_POWER" \
STREAM_DENSITY_MODE=$STREAM_DENSITY_MODE \
INPUTSRC="$INPUTSRC" \
STREAM_DENSITY_FPS=$STREAM_DENSITY_FPS \
STREAM_DENSITY_INCREMENTS=$STREAM_DENSITY_INCREMENTS \
COMPLETE_INIT_DURATION=$COMPLETE_INIT_DURATION \
CPU_ONLY="$CPU_ONLY" \
PIPELINE_PROFILE="$PIPELINE_PROFILE" \
AUTO_SCALE_FLEX_140="$AUTO_SCALE_FLEX_140" \
./profile-launcher -configDir $(dirname $(readlink ./profile-launcher)) > ./results/profile-launcher."$current_time".log 2>&1 &
