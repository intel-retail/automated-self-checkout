#!/bin/bash -e
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

COMMAND=$1
SOURCE_DIR=$(dirname $(dirname "$(readlink -f "$0")"))
CAMERAS=$2

if [ -z "$COMMAND" ]; then
    COMMAND="START"
fi

if [ "${COMMAND,,}" = "start" ]; then

    cd $SOURCE_DIR/sample-media
    FILES=( *.mp4 )

    if [ -z "$CAMERAS" ]; then
	CAMERAS=${#FILES[@]}
    fi

    cd $SOURCE_DIR/camera-simulator
    
    docker run --rm -t --network=host --name camera-simulator aler9/rtsp-simple-server >rtsp_simple_server.log.txt  2>&1 &
    index=0
    echo $CAMERAS
    while [ $index -lt $CAMERAS ]
    do
	      for file in "${FILES[@]}"
	      do
		  echo "Starting camera: rtsp://127.0.0.1:8554/camera_$index from $file"
		  docker run -t --rm --entrypoint ffmpeg --network host -v$SOURCE_DIR/sample-media:/home/pipeline-server/sample-media openvino/ubuntu20_data_runtime:2021.4.2 -nostdin -re -stream_loop -1 -i /home/pipeline-server/sample-media/$file -c copy -f rtsp -rtsp_transport tcp rtsp://localhost:8554/camera_$index >/dev/null 2>&1 &
		  ((index+=1))
		  if [ $CAMERAS -le $index ]; then
		      break
		  fi
		  sleep 1
	      done
    done
	
elif [ "${COMMAND,,}" = "stop" ]; then
    docker kill camera-simulator
fi
    
