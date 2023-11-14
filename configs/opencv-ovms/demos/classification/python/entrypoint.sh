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

python3 classification/python/classification_demo.py -m localhost:"$GRPC_PORT"/models/"$CLASSIFICATION_MODEL_NAME" \
	--label classification/python/labels/"$CLASSIFICATION_LABEL_FILE" -i $INPUTSRC \
	--adapter ovms --output_resolution "$CLASSIFICATION_OUTPUT_RESOLUTION" $mqttArgs 2>&1  | tee >/tmp/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)