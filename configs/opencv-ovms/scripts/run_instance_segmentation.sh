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

CONTAINER_NAME=segmentation"$cid_count"

docker run --network host --env-file <(env) --privileged \
$rmDocker -e DISPLAY=$DISPLAY -e CONTAINER_NAME=$CONTAINER_NAME -v ~/.Xauthority:/home/dlstreamer/.Xauthority \
-v /tmp/.X11-unix --name $CONTAINER_NAME \
-v $RUN_PATH/results:/tmp/results \
python-demo:dev \
python3 instance_segmentation/python/instance_segmentation_demo.py -m localhost:"$GRPC_PORT"/models/instance-segmentation-security-1040 \
--label instance_segmentation/python/coco_80cl_bkgr.txt -i $inputsrc \
--adapter ovms -t 0.85 --show_scores --show_boxes --output_resolution 1280x720 $mqttArgs \
2>&1  | tee >"$RUN_PATH"/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > "$RUN_PATH"/results/pipeline$cid_count.log)