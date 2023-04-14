#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

TARGET_FPS=15
MEETS_FPS=true
INIT_DURATION=120
num_pipelines=0
log=/tmp/results/stream_density.log

if [ ! -z "$STREAM_DENSITY_FPS" ]
then
	TARGET_FPS=$STREAM_DENSITY_FPS
fi

if [ ! -z "$COMPLETE_INIT_DURATION" ]
then
	INIT_DURATION=$COMPLETE_INIT_DURATION
fi

echo "Stream density TARGET_FPS set for $TARGET_FPS and INIT_DURATION set for $INIT_DURATION" > $log
echo "Starting single container stream density benchmarking" >> $log

GPU_DEVICE_TOGGLE="1"

while [ $MEETS_FPS = true ] 
do
	total_fps_per_stream=0.0
	total_fps=0.0
	num_pipelines=$(( $num_pipelines + 1 ))
	cid_count=$(( $num_pipelines - 1 ))

	echo "Starting pipeline: $num_pipelines" >> $log
	if [ -z "$AUTO_SCALE_FLEX_140" ]
	then
		#echo "DEBUG: $1" >> $log
		./$1 &
	else
		echo "INFO: Auto scaling on both flex 140 gpus...targetting device $GPU_DEVICE_TOGGLE" >> $log
		if [ "$GPU_DEVICE_TOGGLE" == "1" ] 
		then
			GST_VAAPI_DRM_DEVICE=/dev/dri/renderD128 ./$1 &
			GPU_DEVICE_TOGGLE=2
		else
			GST_VAAPI_DRM_DEVICE=/dev/dri/renderD129 ./$1 &
			GPU_DEVICE_TOGGLE=1
		fi
	fi

	echo "waiting for pipelines to settle" >> $log
	# let the pipelines settle
	sleep $INIT_DURATION

	for i in $( seq 0 $(($cid_count)))
        do
		#fps=`tail -1 /tmp/results/pipeline$cid_count.log`
		# Last 10/20 seconds worth of currentfps
	        STREAM_FPS_LIST=`tail -20 /tmp/results/pipeline$i.log`
		if [ -z "$STREAM_FPS_LIST" ]
		then
			echo "Warning: No FPS returned from pipeline$i.log"
			STREAM_FPS_LIST=`tail -20 /tmp/results/pipeline$i.log`
			echo "DEBUG: $STREAM_FPS_LIST"
			#continue
		fi
        	stream_fps_sum=0
        	stream_fps_count=0

		for stream_fps in $STREAM_FPS_LIST
        	do
                	stream_fps_sum=`echo $stream_fps_sum $stream_fps | awk '{print $1 + $2}'`
                	stream_fps_count=`echo $stream_fps_count 1 | awk '{print $1 + $2}'`
        	done
        	stream_fps_avg=`echo $stream_fps_sum $stream_fps_count | awk '{print $1 / $2}'`


		total_fps=`echo $total_fps $stream_fps_avg | awk '{print $1 + $2}'`
		total_fps_per_stream=`echo $total_fps $num_pipelines | awk '{print $1 / $2}'`
		echo "FPS for pipeline$i: $stream_fps_avg" >> $log
	done
	echo "Total FPS throughput: $total_fps" >> $log
        echo "Total FPS per stream: $total_fps_per_stream" >> $log

	if (( $(echo $total_fps_per_stream $TARGET_FPS | awk '{if ($1 >= $2) print 1;}') ))
	then
		total_fps=0	
		echo "yes"
	else
		echo "no"
		MEETS_FPS=false
		echo "Max stream density achieved for target FPS $TARGET_FPS is $(( $cid_count ))" >> $log
		echo "Finished stream density benchmarking" >> $log
	fi
	#sleep 10

done #done while
