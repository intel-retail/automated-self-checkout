#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

MQTT="${MQTT:=}"

if [ "$MQTT" != "" ]
then
	mqttArgs="--mqtt ${MQTT}"
fi

python3 instance_segmentation/python/instance_segmentation_demo.py -m localhost:"$GRPC_PORT"/models/instance-segmentation-security-1040 \
--label instance_segmentation/python/coco_80cl_bkgr.txt -i $INPUTSRC \
--adapter ovms -t 0.85 --show_scores --show_boxes --output_resolution 1280x720 $mqttArgs 2>&1  | tee >/tmp/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)