#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

containerDisplayPort=8080
displayPortNum=$(( $cid_count + $containerDisplayPort ))
echo "displayPortNum=$displayPortNum"

if [ ! -z "$DEBUG" ]
then
    ./grpc-go -i $INPUTSRC -u 127.0.0.1:$GRPC_PORT -h 0.0.0.0:$displayPortNum
else
    ./grpc-go -i $INPUTSRC -u 127.0.0.1:$GRPC_PORT -h 0.0.0.0:$displayPortNum 2>&1  | tee >/tmp/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
fi