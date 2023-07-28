#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

if [ ! -z "$DEBUG" ]
then
    ./grpc-go -i $inputsrc -u 127.0.0.1:$GRPC_PORT
else
    ./grpc-go -i $inputsrc -u 127.0.0.1:$GRPC_PORT 2>&1  | tee >/tmp/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
fi