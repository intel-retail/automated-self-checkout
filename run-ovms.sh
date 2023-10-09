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
	if [ $OCR_DISABLED == 0 ]
	then
        	echo "OCR device defaulting to dGPU"
        	OCR_DEVICE=GPU
	fi
fi

if [ ! -z "$CONTAINER_IMAGE_OVERRIDE" ]
then
	echo "Using container image override $CONTAINER_IMAGE_OVERRIDE"
	TAG=$CONTAINER_IMAGE_OVERRIDE
fi

cid_count=`ps aux | grep profile-launcher | grep -v grep | wc -l`

#echo "barcode_disabled: $BARCODE_DISABLED, barcode_interval: $BARCODE_INTERVAL, ocr_interval: $OCR_INTERVAL, ocr_device: $OCR_DEVICE, ocr_disabled=$OCR_DISABLED, class_disabled=$CLASSIFICATION_DIABLED"
pre_process=""
if grep -q "rtsp" <<< "$INPUTSRC"; then
	# rtsp
	# todo pass depay info
	inputsrc=$INPUTSRC
	INPUTSRC_TYPE="RTSP"
	pre_process="pre-process-backend=vaapi-surface-sharing -e pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1"


elif grep -q "file" <<< "$INPUTSRC"; then
	# filesrc	
	arrfilesrc=(${INPUTSRC//:/ })
	# use vids since container maps a volume to this location based on sample-media folder
	# TODO: need to pass demux/codec info
	inputsrc="filesrc location=vids/"${arrfilesrc[1]}" ! qtdemux ! h264parse "
	INPUTSRC_TYPE="FILE"
	decode_type="vaapidecodebin"
	pre_process="pre-process-backend=vaapi-surface-sharing -e pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1"

elif grep -q "video" <<< "$INPUTSRC"; then
	# v4l2src /dev/video*
	# TODO need to pass stream info
	inputsrc=$INPUTSRC
	INPUTSRC_TYPE="USB"
	TARGET_USB_DEVICE="--device=$INPUTSRC"
	decode_type="videoconvert ! video/x-raw,format=BGR"
	pre_process=""

else
	# rs-serial realsenssrc
	# TODO need to pass depthalign info
	inputsrc="realsensesrc cam-serial-number="$INPUTSRC" stream-type=0 align=0 imu_on=false"
    # add realsense color related properties if any
	if [ "$COLOR_WIDTH" != 0 ]; then
		inputsrc=$inputsrc" color-width="$COLOR_WIDTH
	fi
	if [ "$COLOR_HEIGHT" != 0 ]; then
		inputsrc=$inputsrc" color-height="$COLOR_HEIGHT
	fi
	if [ "$COLOR_FRAMERATE" != 0 ]; then
		inputsrc=$inputsrc" color-framerate="$COLOR_FRAMERATE
	fi
	INPUTSRC_TYPE="REALSENSE"
	decode_type="decodebin ! videoconvert ! video/x-raw,format=BGR"
	pre_process=""
	cameras=`ls /dev/vid* | while read line; do echo "--device=$line"; done`
	TARGET_GPU_DEVICE=$TARGET_GPU_DEVICE" "$cameras	
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
		# override logic in workload script so stream density can manage it
		AUTO_SCALE_FLEX_140=2
	else
		# allow workload to manage autoscaling
		AUTO_SCALE_FLEX_140=1
	fi
fi

# make sure models are downloaded or existing:
./download_models/getModels.sh --workload ovms

# make sure sample image is downloaded or existing:
./configs/opencv-ovms/scripts/image_download.sh

# Set GRPC port based on number of servers and clients
GRPC_PORT=$(( 9000 + $cid_count ))

# Modify the config file if the device env is set
# devices supported CPU, GPU, GPU.x, AUTO, MULTI:GPU,CPU
DEVICE="${DEVICE:="CPU"}"
echo "Updating config with device environment variable"
docker run --rm -v `pwd`/configs/opencv-ovms/models/2022:/configFiles -e DEVICE=$DEVICE update_config:dev

# PIPELINE_PROFILE is the environment variable to choose which type of pipelines to run with
# eg. grpc_python, grpc_cgo_binding, ... etc
# one example to run with this pipeline profile on the command line is like:
# PIPELINE_PROFILE="grpc_python" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
PIPELINE_PROFILE="${PIPELINE_PROFILE:=grpc_python}"
echo "starting profile-launcher with pipeline profile: $PIPELINE_PROFILE ..."

cameras="$cameras" \
TARGET_USB_DEVICE="$TARGET_USB_DEVICE" \
TARGET_GPU_DEVICE="$TARGET_GPU_DEVICE" \
MQTT="$MQTT" \
RENDER_MODE=$RENDER_MODE \
INPUTSRC_TYPE=$INPUTSRC_TYPE \
DISPLAY=$DISPLAY \
cl_cache_dir=$cl_cache_dir \
RUN_PATH=`pwd` \
PLATFORM=$PLATFORM \
BARCODE_RECLASSIFY_INTERVAL=$BARCODE_INTERVAL \
OCR_RECLASSIFY_INTERVAL=$OCR_INTERVAL \
OCR_DEVICE=$OCR_DEVICE \
LOG_LEVEL=$LOG_LEVEL \
decode_type="$decode_type" \
pre_process="$pre_process" \
LOW_POWER="$LOW_POWER" \
cid_count=$cid_count \
STREAM_DENSITY_MODE=$STREAM_DENSITY_MODE \
inputsrc="$inputsrc" \
STREAM_DENSITY_FPS=$STREAM_DENSITY_FPS \
STREAM_DENSITY_INCREMENTS=$STREAM_DENSITY_INCREMENTS \
COMPLETE_INIT_DURATION=$COMPLETE_INIT_DURATION \
CPU_ONLY="$CPU_ONLY" \
GRPC_PORT="$GRPC_PORT" \
PIPELINE_PROFILE="$PIPELINE_PROFILE" \
AUTO_SCALE_FLEX_140="$AUTO_SCALE_FLEX_140" \
./profile-launcher -configDir $(dirname $(readlink ./profile-launcher)) &
