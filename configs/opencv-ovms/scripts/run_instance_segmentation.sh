#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# Default values
cid_count="${cid_count:=0}"
INPUTSRC="${INPUTSRC:=}"

rmDocker=--rm
if [ -n "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=""
fi

mqttArgs=""
if [ "$MQTT" != "" ]
then	
	mqttArgs="--mqtt ${MQTT}"
fi

CONTAINER_NAME=segmentation"$cid_count"

DOCKER_ENTRY=./instance_segmentation/python/entrypoint.sh

docker run --network host --privileged \
-e GRPC_PORT="$GRPC_PORT" -e INPUTSRC="$INPUTSRC" -e cid_count="$cid_count" -e RENDER_MODE="$RENDER_MODE" \
$rmDocker -e DISPLAY=$DISPLAY -e CONTAINER_NAME=$CONTAINER_NAME -e mqttArgs="$mqttArgs" -v ~/.Xauthority:/home/dlstreamer/.Xauthority \
-v /tmp/.X11-unix --name $CONTAINER_NAME \
-v "$RUN_PATH"/results:/tmp/results \
python-demo:dev bash -c "'$DOCKER_ENTRY'"