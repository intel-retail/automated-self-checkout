#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

TARGET_FPS=15
MEETS_FPS=true
INIT_DURATION=120
num_pipelines=1
increments=1
log=/tmp/results/stream_density.log


if [ ! -z "$STREAM_DENSITY_FPS" ]
then
	if (( $(echo $STREAM_DENSITY_FPS | awk '{if ($1 <= 0) print 1;}') ))
	then
		echo "ERROR: stream density input target fps should be greater than 0"
		exit 1
	fi
	TARGET_FPS=$STREAM_DENSITY_FPS
fi

if [ ! -z "$COMPLETE_INIT_DURATION" ]
then
	INIT_DURATION=$COMPLETE_INIT_DURATION
fi

echo "Stream density TARGET_FPS set for $TARGET_FPS and INIT_DURATION set for $INIT_DURATION" > $log
echo "Starting single container stream density benchmarking" >> $log

GPU_DEVICE_TOGGLE="1"

decrementing=0
start_cid_count=0
declare -a pipelinePIDs

while [ $MEETS_FPS = true ] 
do
	total_fps_per_stream=0.0
	total_fps=0.0

	cid_count=$(( $num_pipelines - 1 ))

	echo "Starting pipeline: $num_pipelines" >> $log
	if [ -z "$AUTO_SCALE_FLEX_140" ]
	then
		echo "DEBUG: $1" >> $log
		if [ $decrementing -eq 0 ]
		then
			for i in $( seq $(($start_cid_count)) $(($num_pipelines - 1)))
			do
				echo "the first args is $1"
				cid_count=$i
				./$1 &
				pid=$!
				pipelinePIDs+=($pid)
			done
			echo "pipeline pid list: ${pipelinePIDs[@]}"
		else
			# kill the pipeline with index based on the current pipeline number
			pidToKill="${pipelinePIDs[$num_pipelines]}"
			echo "decrementing pipelines and to kill pid $pidToKill"
			kill -9 $pidToKill
			if ps -p $pidToKill > /dev/null
			then
				echo "$pidToKill is still running"
				sleep 2
			fi
			echo "$(ps -aux | grep $1 | grep -v grep)"
			echo
			echo "background running pipeline PIDs: $(jobs -p)"
		fi
	else
		echo "INFO: Auto scaling on both flex 140 gpus...targetting device $GPU_DEVICE_TOGGLE" >> $log
		for i in $( seq $(($start_cid_count)) $(($num_pipelines - 1)))
		do
			if [ $decrementing -eq 0 ]
			then
				cid_count=$i
				if [ "$GPU_DEVICE_TOGGLE" == "1" ]
				then
					GST_VAAPI_DRM_DEVICE=/dev/dri/renderD128 ./$1 &
					GPU_DEVICE_TOGGLE=2
				else
					GST_VAAPI_DRM_DEVICE=/dev/dri/renderD129 ./$1 &
					GPU_DEVICE_TOGGLE=1
				fi
				pid=$!
				pipelinePIDs+=($pid)
				echo "pipeline pid list: ${pipelinePIDs[@]}"
			else
				# kill the pipeline with index based on the current pipeline number
				pidToKill="${pipelinePIDs[$num_pipelines]}"
				echo "decrementing pipelines and to kill pid $pidToKill"
				kill -9 $pidToKill
				if ps -p $pidToKill > /dev/null
				then
					echo "$pidToKill is still running"
					sleep 2
				fi
				echo "$(ps -aux | grep $1 | grep -v grep)"
				echo
				echo "background running pipeline PIDs: $(jobs -p)"
			fi
		done
	fi

	echo "waiting for pipelines to settle" >> $log
	# let the pipelines settle
	if [ $decrementing -eq 0 ]
	then
		sleep $(( $INIT_DURATION * $increments ))
	else
		sleep $INIT_DURATION
	fi

	# note: before reading the pipeline log files
	# we want to give pipelines some time as the log files
	# producing could be lagging behind...
	max_retries=50
	retry=0
	foundAllLogs=0
	while [ $foundAllLogs -ne $num_pipelines ]
	do
		if [ $retry -ge $max_retries ]
		then
			echo "ERROR: cannot find all pipeline log files after retries, pipeline may have been failed..."
			exit 1
		fi

		echo "checking presence of all pipeline log files..."

		foundAllLogs=0
		for i in $( seq 0 $(($cid_count)))
		do
			# to make sure all pipeline log files are present before proceed
			if [ -f "/tmp/results/pipeline$i.log" ]
			then
				echo "found pipeline$i.log file"
				foundAllLogs=$(( $foundAllLogs + 1 ))
			else
				echo "could not find pipeline$i.log file"
			fi
		done
		retry=$(( $retry + 1 ))
		sleep 1
	done

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

	echo "decrementing: $decrementing"
	echo "current total fps per stream = $total_fps_per_stream for $num_pipelines pipeline(s)"

	if [ $decrementing -eq 0 ]
	then
		if (( $(echo $total_fps_per_stream $TARGET_FPS | awk '{if ($1 >= $2) print 1;}') ))
		then
			# calculate the next increments to speed up to reach goal
			# assuming it is linearly distributed for all pipelines
			# based on the total_fps_per_stream
			increments=`echo $total_fps_per_stream $TARGET_FPS | awk '{print int($1 / $2)}'`
			if [ $increments -lt 1 ]
			then
				# the min increment is 1
				increments=1
			fi
			echo "incrementing by $increments"
		else
			increments=-1
			decrementing=1
			echo "Below target fps $TARGET_FPS, starting to decrement pipelines by 1..."
		fi
	else
		if (( $(echo $total_fps_per_stream $TARGET_FPS | awk '{if ($1 >= $2) print 1;}') ))
		then
			echo "found maximum number of pipelines to have target fps $TARGET_FPS"
			MEETS_FPS=false
			echo "Max stream density achieved for target FPS $TARGET_FPS is $(( $num_pipelines ))" >> $log
			echo "Finished stream density benchmarking" >> $log
		else
			if [ $num_pipelines -le 1 ]
			then
				echo "already reach num pipeline 1, and the fps per stream is $total_fps_per_stream but target FPS is $TARGET_FPS" >> $log
				MEETS_FPS=false
				break
			else
				echo "decrementing number of pipelines $num_pipelines by 1"
			fi
		fi
	fi

	start_cid_count=$(( num_pipelines ))
	num_pipelines=$(( $num_pipelines + $increments ))

done #done while
