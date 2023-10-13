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

rmDocker="--rm"
if [ -n "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=
fi

mqttArgs=
if [ "$MQTT" != "" ]
then	
	mqttArgs="--mqtt ${MQTT}"
fi

CONTAINER_NAME=face_detection"$cid_count"

DOCKER_ENTRY=./face_detection/entrypoint.sh

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

TAG=openvino/model_server-capi-gst-ovms:latest

bash_cmd="./launch-pipeline.sh $PIPELINE_EXEC_PATH $INPUTSRC $USE_ONEVPL $RENDER_MODE $RENDER_PORTRAIT_MODE"

echo "BashCmd: $bash_cmd with media on $GST_VAAPI_DRM_DEVICE with USE_ONEVPL=$USE_ONEVPL"
docker run --network host \
 $cameras $TARGET_USB_DEVICE $TARGET_GPU_DEVICE \
 --user root --ipc=host --name $CONTAINER_NAME \
 $stream_density_mount \
 -e GST_VAAPI_DRM_DEVICE=$GST_VAAPI_DRM_DEVICE \
 -v $cl_cache_dir:/home/intel/gst-ovms/.cl-cache \
 -v /tmp/.X11-unix:/tmp/.X11-unix \
 -v `pwd`/sample-media/:/home/intel/gst-ovms/vids \
 -v `pwd`/configs/opencv-ovms/gst_capi/extensions:/home/intel/gst-ovms/extensions \
 -v `pwd`/results:/tmp/results \
 -v `pwd`/configs/opencv-ovms/models/2022/:/home/intel/gst-ovms/models \
 -w /home/intel/gst-ovms \
 $RUN_MODE $stream_density_params \
 --env-file <(env) \
 $TAG "$bash_cmd"