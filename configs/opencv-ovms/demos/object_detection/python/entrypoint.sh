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

python3 object_detection/python/object_detection_demo.py -m localhost:"$GRPC_PORT"/models/"$DETECTION_MODEL_NAME" \
--label object_detection/python/labels/"$DETECTION_LABEL_FILE" -i "$INPUTSRC" \
--adapter ovms -t "$DETECTION_THRESHOLD" -at "$DETECTION_ARCHITECTURE_TYPE" --output_resolution "$DETECTION_OUTPUT_RESOLUTION" \
$mqttArgs 2>&1  | tee >/tmp/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)