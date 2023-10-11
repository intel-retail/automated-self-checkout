#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

GRPC_PORT="${GRPC_PORT:=9000}"
cid_count="${cid_count:=0}"

echo "running grpc_go with GRPC_PORT=$GRPC_PORT"

rmDocker="--rm"
if [ -n "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=
fi

DOCKER_ENTRY="${PipelineStreamDensityRun:=./entrypoint.sh}"

echo "DOCKER_ENTRY: $DOCKER_ENTRY"

docker run --network host $rmDocker \
	-e inputsrc="$inputsrc" \
	-e cid_count="$cid_count" \
	-e GRPC_PORT="$GRPC_PORT" -e DEBUG="$DEBUG" \
	-e RESULT_DIR="/tmp/results" \
	-v "$RUN_PATH"/results:/tmp/results \
	-v "$RUN_PATH"/benchmark-scripts/stream_density.sh:/app/stream_density.sh \
	--name grpc_go"$cid_count" grpc_go:dev bash -c "'$DOCKER_ENTRY'"