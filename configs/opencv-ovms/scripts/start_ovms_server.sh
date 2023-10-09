#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

cid_count="${cid_count:=0}"
GRPC_PORT="${GRPC_PORT:=9000}"

srvContainerNameInstance="$SERVER_CONTAINER_NAME$cid_count"

echo "$OVMS_SERVER_START_UP_MSG"
docker run --network host -d $cameras $TARGET_USB_DEVICE $TARGET_GPU_DEVICE --user root --ipc=host --name $srvContainerNameInstance \
-e cl_cache_dir=$server_cl_cache_dir \
-v $cl_cache_dir:$server_cl_cache_dir \
-v `pwd`/configs/opencv-ovms/models/2022:/models \
$OVMS_SERVER_IMAGE_TAG --config_path $OVMS_MODEL_CONFIG_JSON --port $GRPC_PORT
