#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

error() {
    printf '%s\n' "$1" >&2
    exit 1
}

cid_count="${cid_count:=0}"
DEVICE="${DEVICE:=CPU}"

echo "VOLUMES is: $VOLUMES"
echo "DOCKER image is: $DOCKER_IMAGE"
echo "RUN_PATH: $RUN_PATH"
echo "CONTAINER_NAME: $CONTAINER_NAME"

# Set RENDER_MODE=1 for demo purposes only
RUN_MODE="-itd"
if [ "$RENDER_MODE" == 1 ]
then
	RUN_MODE="-it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix"
fi

echo "DEVICE is: $DEVICE"

# Set GPU device based on target device set
if [ "$DEVICE" == "CPU" ]; then
    echo "Using CPU"
elif [ "$DEVICE" == "MULTI:GPU,CPU" ]; then
    # Set container to privilieged to have access to multiple devices
    TARGET_GPU_DEVICE="--privileged"
elif grep -q "GPU" <<< "$DEVICE"; then	
    # Get device id if GPU.X is set
    arrgpu=(${DEVICE//./ })
    TARGET_GPU_NUMBER=${arrgpu[1]}
    # If GPU is not specified set to privileged so pipline has access to all GPUs
    if [ -z "$TARGET_GPU_NUMBER" ]; then
        TARGET_GPU_DEVICE="--privileged"
    else
        # If GPU is speicified only mount that GPU
        TARGET_GPU_ID=$((128+$TARGET_GPU_NUMBER))
        TARGET_GPU_DEVICE="--device=/dev/dri/renderD"$TARGET_GPU_ID
    fi	
else
    error 'ERROR: "--device" requires an argument CPU|GPU|MULTI'
fi

# Mount the USB if using a usb camera
TARGET_USB_DEVICE=""
if [[ "$INPUTSRC" == *"/dev/vid"* ]]
then
	TARGET_USB_DEVICE="--device=$INPUTSRC"
fi

containerNameInstance="$CONTAINER_NAME$cid_count"

# interpret any nested environment variables inside the VOLUMES if any
volFullExpand=$(eval echo "$VOLUMES")
echo "DEBUG: volFullExpand $volFullExpand"

# volFullExpand is docker volume command and meant to be words splitting
# shellcheck disable=2086
docker run --network host --user root --ipc=host \
--name "$containerNameInstance" \
--env-file <(env) \
$TARGET_USB_DEVICE \
$TARGET_GPU_DEVICE \
$volFullExpand \
$RUN_MODE \
"$DOCKER_IMAGE" \
$DOCKER_CMD
