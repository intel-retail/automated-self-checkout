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

echo "Note: Pipeline log and results are available at location - ./results"
# generate unique container id based on the date with the precision upto nano-seconds
cid=$(date +%Y%m%d%H%M%S%N)
echo "cid: $cid"

python3 classification/python/classification_demo.py -m localhost:"$GRPC_PORT"/models/"$CLASSIFICATION_MODEL_NAME" \
	--label classification/python/labels/"$CLASSIFICATION_LABEL_FILE" -i $INPUTSRC \
	--adapter ovms --output_resolution "$CLASSIFICATION_OUTPUT_RESOLUTION" $mqttArgs 2>&1  | tee >/tmp/results/r$cid"_classification".jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid"_classification".log)