#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

cid_count="${cid_count:=0}"

echo "VOLUMES is: $VOLUMES"
echo "DOCKER image is: $DOCKER_IMAGE"
echo "RUN_PATH: $RUN_PATH"
echo "CONTAINER_NAME: $CONTAINER_NAME"

containerNameInstance="$CONTAINER_NAME$cid_count"

# interpret any nested environment variables inside the VOLUMES if any
volFullExpand=$(eval echo "$VOLUMES")
echo "DEBUG: volFullExpand $volFullExpand"

# volFullExpand is docker volume command and meant to be words splitting
# shellcheck disable=2086
docker run --network host --user root --ipc=host \
--name "$containerNameInstance" \
$volFullExpand \
"$DOCKER_IMAGE"
