#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

cid_count="${cid_count:=0}"
cameras="${cameras:=}"
stream_density_mount="${stream_density_mount:=}"
stream_density_params="${stream_density_params:=}"
cl_cache_dir="${cl_cache_dir:=$HOME/.cl-cache}"

COLOR_WIDTH="${COLOR_WIDTH:=1920}"
COLOR_HEIGHT="${COLOR_HEIGHT:=1810}"
COLOR_FRAMERATE="${COLOR_FRAMERATE:=15}"
OCR_SPECIFIED="${OCR_SPECIFIED:=5}"

echo "Run gst pipeline profile"
rmDocker=--rm
if [ -n "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=
fi

echo "$PLATFORM"
if [ "$PLATFORM" == "dgpu" ]; then
	echo "$RUN_PATH/configs/opencv-ovms/envs/yolov5-gpu.env"
	source "$RUN_PATH/configs/opencv-ovms/envs/yolov5-gpu.env"
else
	echo "$RUN_PATH/configs/opencv-ovms/envs/yolov5-cpu.env"
	source "$RUN_PATH/configs/opencv-ovms/envs/yolov5-cpu.env"
fi

echo $rmDocker
TAG=sco-soc:2.0
pipeline="yolov5s.sh"

bash_cmd="/home/pipeline-server/framework-pipelines/yolov5_pipeline/$pipeline"

inputsrc=$INPUTSRC
PRE_PROCESS=""
if grep -q "rtsp" <<< "$INPUTSRC"; then
	# rtsp
	inputsrc=$INPUTSRC" ! rtph264depay "
	DECODE="decodebin force-sw-decoders=1"
	PRE_PROCESS="pre-process-backend=vaapi-surface-sharing -e pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1"
elif grep -q "file" <<< "$INPUTSRC"; then
	arrfilesrc=(${INPUTSRC//:/ })
	# use vids since container maps a volume to this location based on sample-media folder
	# TODO: need to pass demux/codec info
	inputsrc="filesrc location=vids/"${arrfilesrc[1]}" ! qtdemux ! h264parse "
	DECODE="decodebin force-sw-decoders=1"
	PRE_PROCESS="pre-process-backend=vaapi-surface-sharing -e pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1"
elif grep -q "video" <<< "$INPUTSRC"; then
	inputsrc="v4l2src device="$INPUTSRC
	DECODE="decodebin ! videoconvert ! video/x-raw,format=BGR"
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
	DECODE="decodebin ! videoconvert ! video/x-raw,format=BGR"
fi

CONTAINER_NAME=gst"$cid_count"

# there are a few arguments are meant to be used as command line argument like $cameras, $TARGET_USB_DEVICE, ...etc; so we want to split words on space for that
#shellcheck disable=SC2086
docker run --network host $cameras $TARGET_USB_DEVICE $TARGET_GPU_DEVICE --user root --ipc=host \
--name "$CONTAINER_NAME" \
-e CONTAINER_NAME="$CONTAINER_NAME" \
-e RENDER_MODE="$RENDER_MODE" $stream_density_mount -e DISPLAY="$DISPLAY" \
-e cl_cache_dir=/home/pipeline-server/.cl-cache -e RESULT_DIR="/tmp/result" \
-v "$cl_cache_dir":/home/pipeline-server/.cl-cache -v /tmp/.X11-unix:/tmp/.X11-unix -v "$RUN_PATH"/sample-media/:/home/pipeline-server/vids \
-v "$RUN_PATH"/configs/dlstreamer/pipelines:/home/pipeline-server/pipelines -v "$RUN_PATH"/configs/dlstreamer/extensions:/home/pipeline-server/extensions \
-v "$RUN_PATH"/results:/tmp/results -v "$RUN_PATH"/configs/opencv-ovms/models/2022:/home/pipeline-server/models \
-v "$RUN_PATH"/configs/dlstreamer/framework-pipelines:/home/pipeline-server/framework-pipelines \
-w /home/pipeline-server \
-e BARCODE_RECLASSIFY_INTERVAL="$BARCODE_INTERVAL" -e OCR_RECLASSIFY_INTERVAL="$OCR_INTERVAL" -e OCR_DEVICE="$OCR_DEVICE" -e LOG_LEVEL="$LOG_LEVEL" \
-e GST_DEBUG="$GST_DEBUG" -e DECODE="$DECODE" -e pre_process="$pre_process" -e LOW_POWER="$LOW_POWER" -e cid_count="$cid_count" \
-e inputsrc="$inputsrc" $RUN_MODE $stream_density_params -e CPU_ONLY="$CPU_ONLY" -e AUTO_SCALE_FLEX_140="$AUTO_SCALE_FLEX_140" \
"$TAG" bash -c "bash $bash_cmd"
