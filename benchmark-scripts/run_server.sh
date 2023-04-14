#!/bin/bash -e
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

COMMAND=$1
PIPELINE_NUMBER=$2
TAG=sco-soc:2.0
PIPELINE_SERVER_VERSION=0.7.2-beta
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
PARENT_DIR=$(dirname $SOURCE_DIR)
PIPELINE_SERVER_DIR=$SOURCE_DIR/pipeline-server-$PIPELINE_SERVER_VERSION
STARTING_RTSP_PORT=9554
STARTING_PORT=8080

if [ -z "$LOG_LEVEL" ]; then
    LOG_LEVEL=INFO
fi

if [ -z "$GST_DEBUG" ]; then
    GST_DEBUG=0
fi

if [ -z "$COMMAND" ]; then
    COMMAND="START"
fi

if [ "${COMMAND,,}" = "start" ]; then
    mkdir -p $SOURCE_DIR/.cl-cache
    mkdir -p $PARENT_DIR/results
    mkdir -p $PARENT_DIR/rendered

    REDIRECT=""
    if [ "${2,,}" = "quiet" ]; then
	$PIPELINE_SERVER_DIR/docker/run.sh --network host --image postman/newman --name pipeline-server -v $SOURCE_DIR/pipelines:/home/pipeline-server/pipelines -v $SOURCE_DIR/extensions:/home/pipeline-server/extensions -v $SOURCE_DIR/pipeline-server/results:/tmp/results -e cl_cache_dir=/home/pipeline-server/.cl-cache -v $SOURCE_DIR/.cl-cache:/home/pipeline-server/.cl-cache -v $SOURCE_DIR/models:/home/pipeline-server/models -e GST_DEBUG=$GST_DEBUG --enable-rtsp --non-interactive --rtsp-port 9554 >$SOURCE_DIR/server.log.txt 2>&1 &
    else
	export GST_DEBUG=0
	export LOG_LEVEL=INFO
	export ENABLE_RTSP=true
	export IGNORE_INIT_ERRORS=true
	RTSP_PORT=$STARTING_RTSP_PORT
	PORT=$STARTING_PORT
	for i in $( seq 0 $(($PIPELINE_NUMBER - 1)) )
	do
		CONTAINER_NAME="pipeline-server"$(($i + 1))
		LOG_FILE_NAME="server"$(($i + 1))".txt"
		if [ $i = 0 ]; then
		echo "./run.sh --network host --image $TAG --name pipeline-server -v /dev/dri:/dev/dri -v $SOURCE_DIR/../pipeline-server/pipelines:/home/pipeline-server/pipelines -v $SOURCE_DIR/../pipeline-server/extensions:/home/pipeline-server/extensions -v $SOURCE_DIR/results:/tmp/results -v /home/intel-admin/poc-recordings:/home/poc-recordings -v $SOURCE_DIR/../pipeline-server/models/2022:/home/pipeline-server/models -e LOG_LEVEL=$LOG_LEVEL -e GST_DEBUG=$GST_DEBUG --non-interactive"
		./run.sh --network host --image $TAG --name pipeline-server -v `pwd`/../sample-media/:/vids -v /dev/dri:/dev/dri -v $SOURCE_DIR/../pipeline-server/pipelines:/home/pipeline-server/pipelines -v $SOURCE_DIR/../pipeline-server/extensions:/home/pipeline-server/extensions -v $SOURCE_DIR/results:/tmp/results -v /home/intel-admin/poc-recordings:/home/poc-recordings -v $SOURCE_DIR/../pipeline-server/models/2022:/home/pipeline-server/models -e LOG_LEVEL=$LOG_LEVEL -e GST_DEBUG=$GST_DEBUG --non-interactive > server.txt 2>&1 &
		else
		RTSP_PORT=$(($RTSP_PORT + 1))
		PORT=$(($PORT + 1))
		./run.sh --network host --image $TAG --name $CONTAINER_NAME -v `pwd`/../sample-media/:/vids -v $SOURCE_DIR/../pipeline-server/pipelines:/home/pipeline-server/pipelines -v $SOURCE_DIR/../pipeline-server/extensions:/home/pipeline-server/extensions -v $SOURCE_DIR/results:/tmp/results -e cl_cache_dir=/home/pipeline-server/.cl-cache -v $SOURCE_DIR/../pipeline-server/models/2022:/home/pipeline-server/models -e LOG_LEVEL=$LOG_LEVEL -e GST_DEBUG=$GST_DEBUG --entrypoint-args --port=$PORT --non-interactive > $LOG_FILE_NAME 2>&1 &
		fi
	done
    fi
    
elif [ "${COMMAND,,}" = "stop" ]; then
    docker kill pipeline-server
elif [ "${COMMAND,,}" = "attach" ]; then
    docker attach pipeline-server
fi

