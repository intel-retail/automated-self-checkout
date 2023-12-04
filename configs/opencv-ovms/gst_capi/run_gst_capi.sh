#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# Default values
cid_count="${cid_count:=0}"
INPUTSRC="${INPUTSRC:=}"
RENDER_PORTRAIT_MODE="${RENDER_PORTRAIT_MODE:=0}"
GST_VAAPI_DRM_DEVICE="${GST_VAAPI_DRM_DEVICE:=/dev/dri/renderD128}"
USE_ONEVPL="${USE_ONEVPL:=0}"
RENDER_MODE="${RENDER_MODE:=0}"
TARGET_GPU_DEVICE="${TARGET_GPU_DEVICE:=--privileged}"
WINDOW_WIDTH="${WINDOW_WIDTH:=1920}"
WINDOW_HEIGHT="${WINDOW_HEIGHT:=1080}"
DETECTION_THRESHOLD="${DETECTION_THRESHOLD:=0.5}"
BARCODE="${BARCODE:=1}"
OCR_DEVICE="${OCR_DEVICE:=}"

update_media_device_engine() {
	# Use discrete GPU if it exists, otherwise use iGPU or CPU
	if [ "$PLATFORM" != "cpu" ]
	then
		if [ "$HAS_ARC" == "1" ] || [ "$HAS_FLEX_140" == "1" ] || [ "$HAS_FLEX_170" == "1" ]
		then
			GST_VAAPI_DRM_DEVICE=/dev/dri/renderD129
		fi
	fi
}

# This updates the media GPU engine utilized based on the request PLATFOR by user
# The default state of all libva (*NIX) media decode/encode/etc is GPU.0 instance
update_media_device_engine

chmod +x $PIPELINE_EXEC_PATH
bash_cmd="./launch-pipeline.sh $PIPELINE_EXEC_PATH $INPUTSRC $USE_ONEVPL $RENDER_MODE $RENDER_PORTRAIT_MODE $WINDOW_WIDTH $WINDOW_HEIGHT $DETECTION_THRESHOLD $BARCODE"

echo "BashCmd: $bash_cmd with media on $GST_VAAPI_DRM_DEVICE with USE_ONEVPL=$USE_ONEVPL"

cl_cache_dir="/home/intel/gst-ovms/.cl-cache" \
DISPLAY="$DISPLAY" \
RESULT_DIR="/tmp/result" \
LOG_LEVEL="$LOG_LEVEL" \
GST_DEBUG="$GST_DEBUG" \
cid_count="$cid_count" \
INPUTSRC="$INPUTSRC" \
RUN_MODE="$RUN_MODE" \
RENDER_MODE="$RENDER_MODE" \
TARGET_GPU_DEVICE="$TARGET_GPU_DEVICE" \
GST_VAAPI_DRM_DEVICE="$GST_VAAPI_DRM_DEVICE" \
PIPELINE_EXEC_PATH="$PIPELINE_EXEC_PATH" \
RENDER_PORTRAIT_MODE="$RENDER_PORTRAIT_MODE" \
USE_ONEVPL="$USE_ONEVPL" \
DETECTION_THRESHOLD="$DETECTION_THRESHOLD" \
BARCODE="$BARCODE" \
OCR_DEVICE="$OCR_DEVICE" \
$bash_cmd \
2>&1 | tee >/tmp/results/gst-capi_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*FPS: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)