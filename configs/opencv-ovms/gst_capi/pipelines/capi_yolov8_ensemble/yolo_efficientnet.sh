#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

cid_count=0



# User configured parameters
if [ -z "$INPUT_TYPE" ]
then
	echo "INPUT_TYPE is required"
	exit 1
	#INPUT_TYPE="FILE_H264"
	#INPUT_TYPE="RTSP_H265"
fi

if [ -z "$INPUTSRC" ]
then
	echo "INPUTSRC is required"
	exit 1
	#INPUTSRC="sample-video.mp4"
	#INPUTSRC="rtsp://127.0.0.1:8554/camera_0"
fi

CODEC_TYPE=0
if [ "$INPUT_TYPE" == "FILE_H264" ] || [ "$INPUT_TYPE" == "RTSP_H264" ]
then
	CODEC_TYPE=1
elif [ "$INPUT_TYPE" == "FILE_H265" ] || [ "$INPUT_TYPE" == "RTSP_H265" ]
then
	CODEC_TYPE=0
fi

if [ -z "$USE_VPL" ]
then
	USE_VPL=0
fi

if [ -z "$RENDER_MODE" ]
then
	RENDER_MODE=0
fi

if [ -z "$RENDER_PORTRAIT_MODE" ]
then
	RENDER_PORTRAIT_MODE=0
fi

# DEBUGGING prints:
env
ls -al /tmp/

# Direct console output
if [ "$DC" != 1 ]
then
	cid_count=0 /app/gst-ovms/pipelines/yolov8_ensemble/capi_yolov8_ensemble $INPUTSRC $USE_VPL $RENDER_MODE $RENDER_PORTRAIT_MODE $CODEC_TYPE $WINDOW_WIDTH $WINDOW_HEIGHT $DETECTION_THRESHOLD 2>&1 | tee >/tmp/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*FPS: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
else
	cid_count=0 /app/gst-ovms/pipelines/yolov8_ensemble/capi_yolov8_ensemble $INPUTSRC $USE_VPL $RENDER_MODE $RENDER_PORTRAIT_MODE $CODEC_TYPE $WINDOW_WIDTH $WINDOW_HEIGHT $DETECTION_THRESHOLD
fi