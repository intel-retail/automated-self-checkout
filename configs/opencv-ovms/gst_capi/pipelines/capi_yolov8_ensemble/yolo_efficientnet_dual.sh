#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
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
if [ -z "$INPUT_TYPE2" ]
then
	echo "INPUT_TYPE2 is required"
	exit 1
	#INPUT_TYPE2="FILE_H264"
	#INPUT_TYPE2="RTSP_H265"
fi

if [ -z "$INPUTSRC" ]
then
	echo "INPUTSRC is required"
	exit 1
	#INPUTSRC="sample-video.mp4 "
	#INPUTSRC="rtsp://127.0.0.1:8554/camera_0 "
fi
if [ -z "$INPUTSRC2" ]
then
	echo "INPUTSRC2 is required"
	exit 1
	#INPUTSRC2="sample-video.mp4 "
	#INPUTSRC="rtsp://127.0.0.1:8554/camera_0 "
fi

CODEC_TYPE2=""
CODEC_TYPE=0
if [ "$INPUT_TYPE" == "FILE_H264" ] || [ "$INPUT_TYPE" == "RTSP_H264" ]
then
	CODEC_TYPE=1
elif [ "$INPUT_TYPE" == "FILE_H265" ] || [ "$INPUT_TYPE" == "RTSP_H265" ]
then
	CODEC_TYPE=0
fi
if [ "$INPUT_TYPE2" == "FILE_H264" ] || [ "$INPUT_TYPE2" == "RTSP_H264" ]
then
	CODEC_TYPE2=1
elif [ "$INPUT_TYPE2" == "FILE_H265" ] || [ "$INPUT_TYPE2" == "RTSP_H265" ]
then
	CODEC_TYPE2=0
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

if [ "1" == "$LOW_POWER" ]
then
	echo "Enabled GPU based low power pipeline "
	CONFIG_NAME="/app/gst-ovms/pipelines/yolov8_ensemble/models/config_yolov8_ensemble_gpu.json"
	
elif [ "$CPU_ONLY" == "1" ] 
then
	echo "Enabled CPU inference pipeline only"
	CONFIG_NAME="/app/gst-ovms/pipelines/yolov8_ensemble/models/config_yolov8_ensemble_cpu.json"
else
	echo "Enabled CPU+iGPU pipeline"
	CONFIG_NAME="/app/gst-ovms/pipelines/yolov8_ensemble/models/config_yolov8_ensemble_cpu_gpu.json"
fi

# Direct console output
if [ -z "$DC" ]
then
	cid_count=0 /app/gst-ovms/pipelines/yolov8_ensemble/yolov8_ensemble $INPUTSRC $INPUTSRC2 $USE_VPL $RENDER_MODE $RENDER_PORTRAIT_MODE $CONFIG_NAME $CODEC_TYPE $CODEC_TYPE2 > /app/yolov8_ensemble/results/pipeline$cid_count.log 2>&1
else
	cid_count=0 /app/gst-ovms/pipelines/yolov8_ensemble/yolov8_ensemble $INPUTSRC $INPUTSRC2 $USE_VPL $RENDER_MODE $RENDER_PORTRAIT_MODE $CONFIG_NAME $CODEC_TYPE $CODEC_TYPE2
fi