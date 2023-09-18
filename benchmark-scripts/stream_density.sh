#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# this function cleans up parent process and its child processes
# the first input is the parent process to be cleaned up
cleanupPipelineProcesses()
{
	pidToKill=$1
	childPids=$(pgrep -P "$pidToKill")
	echo "decrementing pipelines and to kill pid $pidToKill" >> "$log"
	waitForChildPidKilled=0
	if [ -z "$childPids" ]
	then
		echo "for parent pid $pidToKill, there is no child pids to kill" >> "$log"
	else
		echo "parent pid $pidToKill with childPids $childPids to be killed" >> "$log"
		waitForChildPidKilled=1
	fi

	# kill the parent process with PID $pidToKill
	pkill -P "$pidToKill"

	# make sure all child pids are gone before proceed
	MAX_PID_WAITING_COUNT=10
	waitingCnt=0
	while [ $waitForChildPidKilled -eq 1 ]
	do
		numExistingChildren=0
		for childPid in $childPids
		do
			if ps -p "$childPid" > /dev/null
			then
				echo "child pid: $childPid exists"
				numExistingChildren=$(( numExistingChildren + 1 ))
				if [ $waitingCnt -ge $MAX_PID_WAITING_COUNT ]
				then
					echo "exceeding the max. pid waiting count $MAX_PID_WAITING_COUNT, kill it directly..."  >> "$log"
					kill -9 "$childPid"
					waitingCnt=0
				fi
			else
				echo "no child pid exists $childPid"
			fi
		done

		if [ $numExistingChildren -eq 0 ]
		then
			echo "all child processes for $pidToKill are cleaned up"
			break
		else
			waitingCnt=$(( waitingCnt + 1 ))
		fi
	done

	# check the parent process is gone before proceed
	while ps -p "$pidToKill" > /dev/null
	do
		echo "$pidToKill is still running"
		sleep 1
	done
	echo "done with clean up parent process $pidToKill"
}

TARGET_FPS=15
MEETS_FPS=true
INIT_DURATION=120
MAX_GUESS_INCREMENTS=5
num_pipelines=1
increments=1
log=/tmp/results/stream_density.log

if [ -n "$STREAM_DENSITY_FPS" ]
then
	if (( $(echo "$STREAM_DENSITY_FPS" | awk '{if ($1 <= 0) print 1;}') ))
	then
		echo "ERROR: stream density input target fps should be greater than 0" >> "$log"
		exit 1
	fi
	TARGET_FPS=$STREAM_DENSITY_FPS
fi

if [ -n "$STREAM_DENSITY_INCREMENTS" ]
then
	if (( $(echo "$STREAM_DENSITY_INCREMENTS" | awk '{if ($1 <= 0) print 1;}') ))
	then
		echo "ERROR: stream density input increments should be greater than 0" >> "$log"
		exit 1
	fi
fi

if [ -n "$COMPLETE_INIT_DURATION" ]
then
	INIT_DURATION=$COMPLETE_INIT_DURATION
fi

echo "Stream density TARGET_FPS set for $TARGET_FPS and INIT_DURATION set for $INIT_DURATION" > "$log"
echo "Starting single container stream density benchmarking" >> "$log"

GPU_DEVICE_TOGGLE="1"

decrementing=0
start_cid_count=0
declare -a pipelinePIDs

while [ $MEETS_FPS = true ] 
do
	total_fps_per_stream=0.0
	total_fps=0.0

	cid_count=$(( num_pipelines - 1 ))

	echo "Starting pipeline: $num_pipelines" >> "$log"
	if [ -z "$AUTO_SCALE_FLEX_140" ]
	then
		echo "DEBUG: $1" >> "$log"
		if [ $decrementing -eq 0 ]
		then
			for i in $( seq $(( start_cid_count )) $(( num_pipelines - 1 )))
			do
				echo "the first args is $1"
				cid_count=$i
				$1 &
				pid=$!
				pipelinePIDs+=("$pid")
			done
			echo "pipeline pid list: " "${pipelinePIDs[@]}"
		else
			# kill the pipeline with index based on the current pipeline number
			pidToKill="${pipelinePIDs[$num_pipelines]}"
			cleanupPipelineProcesses "$pidToKill"
			pgrep -fa "$1"
			echo
			echo "current background running pipeline PIDs: $(jobs -p)"
		fi
	else
		echo "INFO: Auto scaling on both flex 140 gpus...targetting device $GPU_DEVICE_TOGGLE" >> "$log"
		for i in $( seq $(( start_cid_count )) $(( num_pipelines - 1 )))
		do
			if [ $decrementing -eq 0 ]
			then
				cid_count=$i
				if [ "$GPU_DEVICE_TOGGLE" == "1" ]
				then
					GST_VAAPI_DRM_DEVICE=/dev/dri/renderD128 $1 &
					GPU_DEVICE_TOGGLE=2
				else
					GST_VAAPI_DRM_DEVICE=/dev/dri/renderD129 $1 &
					GPU_DEVICE_TOGGLE=1
				fi
				pid=$!
				pipelinePIDs+=("$pid")
				echo "pipeline pid list: " "${pipelinePIDs[@]}"
			else
				# kill the pipeline with index based on the current pipeline number
				pidToKill="${pipelinePIDs[$num_pipelines]}"
				cleanupPipelineProcesses "$pidToKill"
				pgrep -fa "$1"
				echo
				echo "current background running pipeline PIDs: $(jobs -p)"
			fi
		done
	fi

	echo "waiting for pipelines to settle" >> "$log"
	sleep "$INIT_DURATION"

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
			echo "ERROR: cannot find all pipeline log files after retries, pipeline may have been failed..." >> "$log"
			exit 1
		fi

		echo "checking presence of all pipeline log files..."

		foundAllLogs=0
		for i in $( seq 0 $(( cid_count )))
		do
			# to make sure all pipeline log files are present before proceed
			if [ -f "/tmp/results/pipeline$i.log" ]
			then
				echo "found pipeline$i.log file" >> "$log"
				foundAllLogs=$(( foundAllLogs + 1 ))
			else
				echo "could not find pipeline$i.log file"  >> "$log"
			fi
		done
		retry=$(( retry + 1 ))
		sleep 1
	done

	for i in $( seq 0 $(( cid_count )))
        do
		# Last 10/20 seconds worth of currentfps
	    STREAM_FPS_LIST=$(tail -20 /tmp/results/pipeline"$i".log)
		if [ -z "$STREAM_FPS_LIST" ]
		then
			echo "Warning: No FPS returned from pipeline$i.log"
			STREAM_FPS_LIST=$(tail -20 /tmp/results/pipeline"$i".log)
		fi
        stream_fps_sum=0
        stream_fps_count=0

		for stream_fps in $STREAM_FPS_LIST
        do
                	stream_fps_sum=$(echo "$stream_fps_sum" "$stream_fps" | awk '{print $1 + $2}')
                	stream_fps_count=$(echo "$stream_fps_count" 1 | awk '{print $1 + $2}')
        done
        stream_fps_avg=$(echo "$stream_fps_sum" "$stream_fps_count" | awk '{print $1 / $2}')


		total_fps=$(echo "$total_fps" "$stream_fps_avg" | awk '{print $1 + $2}')
		total_fps_per_stream=$(echo "$total_fps" "$num_pipelines" | awk '{print $1 / $2}')
		echo "FPS for pipeline$i: $stream_fps_avg" >> "$log"
	done
	echo "Total FPS throughput: $total_fps" >> "$log"
	echo "Total FPS per stream: $total_fps_per_stream" >> "$log"

	echo "decrementing: $decrementing"
	echo "current total fps per stream = $total_fps_per_stream for $num_pipelines pipeline(s)"

	if [ "$decrementing" -eq 0 ]
	then
		if (( $(echo "$total_fps_per_stream" "$TARGET_FPS" | awk '{if ($1 >= $2) print 1;}') ))
		then
			# if the increments hint from $STREAM_DENSITY_INCREMENTS is not empty
			# we will use it as the increments
			# otherwise, we will try to adjust increments dynamically based on the rate of $total_fps_per_stream
			# and $TARGET_FPS
			if [ -n "$STREAM_DENSITY_INCREMENTS" ]
			then
				# there is increments hint from the input, so we will honor it
				# after the first pipeline, the stream density increments will be appiled if we are not there yet
				increments=$STREAM_DENSITY_INCREMENTS
			else
				# when there is no increments hint from input, the value of increments is calculated
				# by the rate of $total_fps_per_stream and $TARGET_FPS per greedy policy
				increments=$(echo "$total_fps_per_stream" "$TARGET_FPS" | awk '{print int($1 / $2)}')
				# when calculated increments is == 1 under this case, the internal maximum increments
				# will be used as there is no effective way to figure out what's the best increments in this case
				if [ "$increments" -eq 1 ]
				then
					increments=$MAX_GUESS_INCREMENTS
				fi
			fi
			echo "incrementing by $increments"
		else
			increments=-1
			decrementing=1
			echo "Below target fps $TARGET_FPS, starting to decrement pipelines by 1..."
		fi
	else
		if (( $(echo "$total_fps_per_stream" "$TARGET_FPS" | awk '{if ($1 >= $2) print 1;}') ))
		then
			echo "found maximum number of pipelines to have target fps $TARGET_FPS"
			MEETS_FPS=false
			echo "Max stream density achieved for target FPS $TARGET_FPS is $num_pipelines" >> "$log"
			echo "Finished stream density benchmarking" >> "$log"
		else
			if [ "$num_pipelines" -le 1 ]
			then
				echo "already reach num pipeline 1, and the fps per stream is $total_fps_per_stream but target FPS is $TARGET_FPS" >> "$log"
				MEETS_FPS=false
				break
			else
				echo "decrementing number of pipelines $num_pipelines by 1"
			fi
		fi
	fi

	start_cid_count=$(( num_pipelines ))
	num_pipelines=$(( num_pipelines + increments ))

done #done while

echo "stream_density done!" >> "$log"
