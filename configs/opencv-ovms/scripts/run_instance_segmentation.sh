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

docker run --network host --env-file <(env) --privileged \
$rmDocker -e DISPLAY=$DISPLAY -v ~/.Xauthority:/home/dlstreamer/.Xauthority \
-v /tmp/.X11-unix --name segmentation"$cid_count" \
-v $RUN_PATH/results:/tmp/results \
instance-segmentation:dev \
python3 instance_segmentation_demo.py -m localhost:9000/models/instance_segmentation_omz_1040 \
--label coco_80cl_bkgr.txt -i $inputsrc \
--adapter ovms -t 0.85 --show_scores \
2>&1  | tee >/tmp/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)