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
COLOR_HEIGHT="${COLOR_HEIGHT:=1080}"
COLOR_FRAMERATE="${COLOR_FRAMERATE:=15}"
OCR_SPECIFIED="${OCR_SPECIFIED:=5}"

echo "Run gst pipeline profile"
cd /home/pipeline-server

rmDocker=--rm
if [ -n "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=
fi

echo "$PLATFORM"
if [ "$PLATFORM" == "dgpu" ]; then
	echo /home/pipeline-server/envs/yolov5-gpu.env
	source /home/pipeline-server/envs/yolov5-gpu.env
else
	echo /home/pipeline-server/envs/yolov5-cpu.env
	source /home/pipeline-server/envs/yolov5-cpu.env
fi

echo $rmDocker
pipeline="yolov5s.sh"

bash_cmd="/home/pipeline-server/framework-pipelines/yolov5_pipeline/$pipeline"

inputsrc=$INPUTSRC
if grep -q "rtsp" <<< "$INPUTSRC"; then
	# rtsp
	inputsrc=$INPUTSRC" ! rtph264depay "
elif grep -q "file" <<< "$INPUTSRC"; then
	arrfilesrc=(${INPUTSRC//:/ })
	# use vids since container maps a volume to this location based on sample-media folder
	inputsrc="filesrc location=vids/"${arrfilesrc[1]}" ! qtdemux ! h264parse "
elif grep -q "video" <<< "$INPUTSRC"; then
	inputsrc="v4l2src device="$INPUTSRC
	DECODE="$DECODE ! videoconvert ! video/x-raw,format=BGR"
	# when using realsense camera, the dgpu.0 not working
else
	# rs-serial realsenssrc
	inputsrc="realsensesrc cam-serial-number="$INPUTSRC" stream-type=0 align=0 imu_on=false"
	echo "----- in run_gst.sh COLOR_WIDTH=$COLOR_WIDTH, COLOR_HEIGHT=$COLOR_HEIGHT, COLOR_FRAMERATE=$COLOR_FRAMERATE"

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
	DECODE="$DECODE ! videoconvert ! video/x-raw,format=BGR"
	# when using realsense camera, the dgpu.0 not working
fi

cl_cache_dir="/home/pipeline-server/.cl-cache" \
DISPLAY="$DISPLAY" \
RESULT_DIR="/tmp/result" \
DECODE="$DECODE" \
DEVICE="$DEVICE" \
PRE_PROCESS="$PRE_PROCESS" \
AGGREGATE="$AGGREGATE" \
OUTPUTFORMAT="$OUTPUTFORMAT" \
BARCODE_RECLASSIFY_INTERVAL="$BARCODE_INTERVAL" \
OCR_RECLASSIFY_INTERVAL="$OCR_INTERVAL" \
OCR_DEVICE="$OCR_DEVICE" \
LOG_LEVEL="$LOG_LEVEL" \
GST_DEBUG="$GST_DEBUG" \
LOW_POWER="$LOW_POWER" \
cid_count="$cid_count" \
inputsrc="$inputsrc" \
RUN_MODE="$RUN_MODE" \
CPU_ONLY="$CPU_ONLY" \
AUTO_SCALE_FLEX_140="$AUTO_SCALE_FLEX_140" \
"$bash_cmd"
