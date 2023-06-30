#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

CAMERA_ID=$1
DEVICE=$2
TARGET_FPS=14.5
MEETS_FPS=true
#start one stream, check fps, if good, stop the server and start two streams. 
num_pipelines=1
while [ $MEETS_FPS = true ] 
do
  	echo "Starting RTSP stream"
        ./camera-simulator.sh
	sleep 10
	echo "Starting pipelines. Device: $DEVICE"
	#docker-run needs to run in it's directory for the file paths to work
	cd ../
	for i in $( seq 0 $(($num_pipelines)))
	do
	  echo "pipeline $i"
	  ./docker-run.sh --platform $DEVICE --inputsrc $CAMERA_ID 
	done
	cd - || { echo "ERROR: failed to change back to the previous directory"; exit 1; }
	echo "waiting for pipelines to settle"
	#time to let the pipelines settle
	sleep 120

	fps=`tail -1 ../results/pipeline0.log`
	echo "FPS for total number of pipeline $(($i + 1)): $fps"
	if (( $(echo $fps $TARGET_FPS | awk '{if ($1 > $2) print 1;}') ))
	then
		echo "yes"
	else
		echo "no"
		MEETS_FPS=false
		echo "Max number of pipelines: $(( $num_pipelines ))"
	fi

	echo "Stopping server"
	./stop_server.sh
	sleep 30
	num_pipelines=$(( $num_pipelines + 1 ))
done #done while
