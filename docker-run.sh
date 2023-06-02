#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

export GST_DEBUG=0

source benchmark-scripts/get-gpu-info.sh

if [ -z "$PLATFORM" ] || [ -z "$INPUTSRC" ]
then
	source get-options.sh "$@"
fi

cl_cache_dir=`pwd`/.cl-cache
echo "CLCACHE: $cl_cache_dir"

#HAS_FLEX_140=$HAS_FLEX_140, HAS_FLEX_170=$HAS_FLEX_170, HAS_ARC=$HAS_ARC

# TODO: override tag for other images and workloads
if [ $HAS_FLEX_140 == 1 ] || [ $HAS_FLEX_170 == 1 ] || [ $HAS_ARC == 1 ] 
then
	if [ $OCR_DISABLED == 0 ]
	then
        	echo "OCR device defaulting to dGPU"
        	OCR_DEVICE=GPU
	fi
	if [ $PLATFORM == "dgpu" ]
	then
		echo "Arc/Flex device driver stack"
		TAG=sco-dgpu:2.0
	else
		TAG=sco-soc:2.0
		echo "SOC (CPU, iGPU, and Xeon SP) device driver stack"
	fi

	if [ $HAS_ARC == 1 ]; then
		PLATFORM="arc"
	fi

else
	echo "SOC (CPU, iGPU, and Xeon SP) device driver stack"
	TAG=sco-soc:2.0
fi

if [ ! -z "$CONTAINER_IMAGE_OVERRIDE" ]
then
	echo "Using container image override $CONTAINER_IMAGE_OVERRIDE"
	TAG=$CONTAINER_IMAGE_OVERRIDE
fi

cids=$(docker ps  --filter="name=automated-self-checkout" -q -a)
cid_count=`echo "$cids" | wc -w`
CONTAINER_NAME="automated-self-checkout"$(($cid_count))
LOG_FILE_NAME="automated-self-checkout"$(($cid_count))".log"

#echo "barcode_disabled: $BARCODE_DISABLED, barcode_interval: $BARCODE_INTERVAL, ocr_interval: $OCR_INTERVAL, ocr_device: $OCR_DEVICE, ocr_disabled=$OCR_DISABLED, class_disabled=$CLASSIFICATION_DIABLED"
pre_process=""
if grep -q "rtsp" <<< "$INPUTSRC"; then
	# rtsp
	# todo pass depay info
	inputsrc=$INPUTSRC" ! rtph264depay "
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
	inputsrc="v4l2src device="$INPUTSRC
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

if [ "${OCR_DISABLED}" == "0" ] && [ "${BARCODE_DISABLED}" == "0" ] && [ "${CLASSIFICATION_DISABLED}" == "0" ] && [ "${REALSENSE_ENABLED}" == "0" ]; then
	pipeline="yolov5s_full.sh"
	
elif [ "${OCR_DISABLED}" == "1" ] && [ "${BARCODE_DISABLED}" == "1" ] && [ "${CLASSIFICATION_DISABLED}" == "1" ]; then
	pipeline="yolov5s.sh"
elif [ "${OCR_DISABLED}" == "1" ] && [ "${BARCODE_DISABLED}" == "1" ] && [ "${CLASSIFICATION_DISABLED}" == "0" ]; then
	pipeline="yolov5s_effnetb0.sh"
elif [ "${REALSENSE_ENABLED}" == "1" ]; then
	# TODO: this will not work for diff pipelines like _full and _effnetb0 etc
	pipeline="yolov5s_realsense.sh"
	
else
	echo "Not implemented"
	exit 0
fi

# Set RENDER_MODE=1 for demo purposes only
RUN_MODE="-itd"
if [ "$RENDER_MODE" == 1 ]
then
	RUN_MODE="-it"
fi

bash_cmd="framework-pipelines/$PLATFORM/$pipeline"
if [ "$STREAM_DENSITY_MODE" == 1 ]; then
	echo "Starting Stream Density"
	bash_cmd="./stream_density_framework-pipelines.sh framework-pipelines/$PLATFORM/$pipeline"
	stream_density_mount="-v `pwd`/configs/framework-pipelines/stream_density.sh:/home/pipeline-server/stream_density_framework-pipelines.sh"
	stream_density_params="-e STREAM_DENSITY_FPS=$STREAM_DENSITY_FPS -e COMPLETE_INIT_DURATION=$COMPLETE_INIT_DURATION"
	echo "DEBUG: $stream_density_params"
fi

#echo "DEBUG: $TARGET_GPU_DEVICE $PLATFORM $HAS_FLEX_140"
if [ "$TARGET_GPU_DEVICE" == "--privileged" ] && [ "$PLATFORM" == "dgpu" ] && [ $HAS_FLEX_140 == 1 ]
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
./modelDownload.sh

docker run --network host $cameras $TARGET_USB_DEVICE $TARGET_GPU_DEVICE --user root --ipc=host --name automated-self-checkout$cid_count -e RENDER_MODE=$RENDER_MODE $stream_density_mount -e INPUTSRC_TYPE=$INPUTSRC_TYPE -e DISPLAY=$DISPLAY -e cl_cache_dir=/home/pipeline-server/.cl-cache -v $cl_cache_dir:/home/pipeline-server/.cl-cache -v /tmp/.X11-unix:/tmp/.X11-unix -v `pwd`/sample-media/:/home/pipeline-server/vids -v `pwd`/configs/pipelines:/home/pipeline-server/pipelines -v `pwd`/configs/extensions:/home/pipeline-server/extensions -v `pwd`/results:/tmp/results -v `pwd`/configs/models/2022:/home/pipeline-server/models -v `pwd`/configs/framework-pipelines:/home/pipeline-server/framework-pipelines -w /home/pipeline-server -e BARCODE_RECLASSIFY_INTERVAL=$BARCODE_INTERVAL -e OCR_RECLASSIFY_INTERVAL=$OCR_INTERVAL -e OCR_DEVICE=$OCR_DEVICE -e LOG_LEVEL=$LOG_LEVEL -e GST_DEBUG=$GST_DEBUG -e decode_type="$decode_type" -e pre_process="$pre_process" -e LOW_POWER="$LOW_POWER" -e cid_count=$cid_count -e inputsrc="$inputsrc" $RUN_MODE $stream_density_params -e CPU_ONLY="$CPU_ONLY" -e AUTO_SCALE_FLEX_140="$AUTO_SCALE_FLEX_140" --rm $TAG bash -c "$bash_cmd"
