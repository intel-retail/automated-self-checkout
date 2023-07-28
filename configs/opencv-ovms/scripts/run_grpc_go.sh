#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

GRPC_PORT="${GRPC_PORT:=9000}"

echo "running grpc_go with GRPC_PORT=$GRPC_PORT"

# /scripts is mounted during the docker run 

rmDocker=--rm
if [ ! -z "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=""
fi

echo $rmDocker
docker run --network host --privileged $rmDocker -e inputsrc="$inputsrc" -e cid_count="$cid_count" -e GRPC_PORT="$GRPC_PORT" -e DEBUG="$DEBUG" -v $RUN_PATH/results:/tmp/results --name dev -p 8080:8080 grpc:dev