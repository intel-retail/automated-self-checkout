#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

rmDocker=--rm
if [ ! -z "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=""
fi

mqttArgs=""
if [ "$MQTT" != "" ]
then	
	mqttArgs="--mqtt ${MQTT}"
fi

CONTAINER_NAME=classification"$cid_count"

docker run --network host --env-file <(env) --privileged $rmDocker \
	-e DISPLAY=$DISPLAY -e CONTAINER_NAME=$CONTAINER_NAME -v ~/.Xauthority:/home/dlstreamer/.Xauthority \
	-v /tmp/.X11-unix --name $CONTAINER_NAME \
	-v $RUN_PATH/results:/tmp/results \
	python-demo:dev \
	python3 classification/python/classification_demo.py -m localhost:"$GRPC_PORT"/models/"$CLASSIFICATION_MODEL_NAME" \
	--label classification/python/labels/"$CLASSIFICATION_LABEL_FILE" -i $inputsrc \
	--adapter ovms --output_resolution "$CLASSIFICATION_OUTPUT_RESOLUTION" \
	# note the $mqttArgs is the commandline args for python to take, so we meant to split the words here
	# shellcheck disable=SC2086
	$mqttArgs \
2>&1  | tee >"$RUN_PATH"/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > "$RUN_PATH"/results/pipeline$cid_count.log)