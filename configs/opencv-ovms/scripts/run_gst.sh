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
decode_type="${decode_type:=}"
pre_process="${pre_process:=}"

echo "Run gst pipeline profile"
rmDocker=--rm
if [ -n "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=
fi

echo $rmDocker
TAG=dlstreamer:2.0
pipeline="yolov5s.sh"

bash_cmd="/home/pipeline-server/framework-pipelines/yolov5_pipeline/$pipeline"

if grep -q "rtsp" <<< "$inputsrc"; then
	# rtsp
	inputsrc=$inputsrc" ! rtph264depay "
fi

CONTAINER_NAME=gst"$cid_count"

# there are a few arguments are meant to be used as command line argument like $cameras, $TARGET_USB_DEVICE, ...etc; so we want to split words on space for that
#shellcheck disable=SC2086
docker run --network host $cameras $TARGET_USB_DEVICE $TARGET_GPU_DEVICE --user root --ipc=host \
--name "$CONTAINER_NAME" \
-e CONTAINER_NAME="$CONTAINER_NAME" \
-e RENDER_MODE="$RENDER_MODE" $stream_density_mount -e INPUTSRC_TYPE="$INPUTSRC_TYPE" -e DISPLAY="$DISPLAY" \
-e cl_cache_dir=/home/pipeline-server/.cl-cache -e RESULT_DIR="/tmp/result" \
-v "$cl_cache_dir":/home/pipeline-server/.cl-cache -v /tmp/.X11-unix:/tmp/.X11-unix -v "$RUN_PATH"/sample-media/:/home/pipeline-server/vids \
-v "$RUN_PATH"/configs/dlstreamer/pipelines:/home/pipeline-server/pipelines -v "$RUN_PATH"/configs/dlstreamer/extensions:/home/pipeline-server/extensions \
-v "$RUN_PATH"/results:/tmp/results -v "$RUN_PATH"/configs/opencv-ovms/models/2022:/home/pipeline-server/models \
-v "$RUN_PATH"/configs/dlstreamer/framework-pipelines:/home/pipeline-server/framework-pipelines \
-w /home/pipeline-server \
-e BARCODE_RECLASSIFY_INTERVAL="$BARCODE_INTERVAL" -e OCR_RECLASSIFY_INTERVAL="$OCR_INTERVAL" -e OCR_DEVICE="$OCR_DEVICE" -e LOG_LEVEL="$LOG_LEVEL" \
-e GST_DEBUG="$GST_DEBUG" -e decode_type="$decode_type" -e pre_process="$pre_process" -e LOW_POWER="$LOW_POWER" -e cid_count="$cid_count" \
-e inputsrc="$inputsrc" $RUN_MODE $stream_density_params -e CPU_ONLY="$CPU_ONLY" -e AUTO_SCALE_FLEX_140="$AUTO_SCALE_FLEX_140" \
"$TAG" bash -c "bash $bash_cmd"
