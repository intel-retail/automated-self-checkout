#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# Default values
cid_count="${cid_count:=0}"
inputsrc="${inputsrc:=}"

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

CONTAINER_NAME=object-detection"$cid_count"

DOCKER_ENTRY=./object_detection/python/entrypoint.sh

docker run --network host --privileged --env-file "$PWD"/envs/object_detection.env  $rmDocker \
-e GRPC_PORT="$GRPC_PORT" -e inputsrc="$inputsrc" -e cid_count="$cid_count" -e RENDER_MODE="$RENDER_MODE" \
-e DISPLAY="$DISPLAY" -e CONTAINER_NAME="$CONTAINER_NAME" -e mqttArgs="$mqttArgs" \
-v ~/.Xauthority:/home/dlstreamer/.Xauthority \
-v /tmp/.X11-unix \
-v "$RUN_PATH"/results:/tmp/results \
--name "$CONTAINER_NAME" \
python-demo:dev bash -c "'$DOCKER_ENTRY'"

