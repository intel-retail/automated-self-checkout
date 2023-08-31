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

CONTAINER_NAME=object-detection"$cid_count"

docker run --network host --env-file <(env) --privileged $rmDocker \
-e DISPLAY=$DISPLAY -e CONTAINER_NAME=$CONTAINER_NAME -v ~/.Xauthority:/home/dlstreamer/.Xauthority \
-v /tmp/.X11-unix --name $CONTAINER_NAME \
-v $RUN_PATH/results:/tmp/results \
python-demo:dev \
python3 object_detection/python/object_detection_demo.py -m localhost:"$GRPC_PORT"/models/person_vehicle_bike_detection_2000 \
--label object_detection/python/labels/person_vehicle_bike_detection_2000.txt -i $inputsrc \
--adapter ovms -t 0.50 -at ssd --output_resolution 1280x720 $mqttArgs \
2>&1  | tee >/tmp/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)