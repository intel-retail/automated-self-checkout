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

DOCKER_ENTRY="${PipelineStreamDensityRun:=./entrypoint.sh}"

echo "DOCKER_ENTRY: $DOCKER_ENTRY"

docker run --network host --privileged $rmDocker \
	-e inputsrc="$inputsrc" -e cid_count="$cid_count" -e GRPC_PORT="$GRPC_PORT" -e DEBUG="$DEBUG" \
	-v $RUN_PATH/results:/tmp/results \
	-v $RUN_PATH/configs/dlstreamer/framework-pipelines/stream_density.sh:/home/pipeline-server/stream_density_framework-pipelines.sh \
	-v $RUN_PATH/configs/opencv-ovms/grpc_go/entrypoint.sh:/app/entrypoint.sh \
	-v $RUN_PATH/configs/opencv-ovms/grpc_go/stream_density_run.sh:/app/stream_density_run.sh \
	--name dev"$cid_count" grpc:dev bash -c "'$DOCKER_ENTRY'"