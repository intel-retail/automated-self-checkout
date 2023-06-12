#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

WATCH_LOG_DIR=$1  # like ../results/
WATCH_POLL_INTERVAL_IN_SECOND=$2  # usually per second polling
NUM_PIPELINES=$3  # number of pipelines: this determines how many pipeline log files to compare with

if [ ! -d "$WATCH_LOG_DIR" ]; then
    echo "ERROR: cannot find the log directory: $WATCH_LOG_DIR"
    exit 1
fi

if [ $NUM_PIPELINES -lt 2 ]; then
    echo "nothing to compare with, exiting"
    exit 0
fi

PIPELINE_FILE_PREFIX=pipeline

log_files=$(find "$WATCH_LOG_DIR" -name "$PIPELINE_FILE_PREFIX*.log" -printf '%p\n')
num_log_files=$(echo "$log_files" | wc -l)

echo "INFO: find $num_log_files log files in $WATCH_LOG_DIR"

if [ "$num_log_files" -lt "$NUM_PIPELINES" ]; then
    echo "ERROR: expecting $NUM_PIPELINES log files but only found $num_log_files"
    exit 1
fi

while true
do
    echo "log file timestamp monitor running ..."
    times=()
    for log_file in $log_files
    do
        t=$(stat -c %Y "$log_file")
	echo "timestamp for $log_file is $t"
        times+=("$t")
    done

    # calculate time difference and stall threshold
    STALL_THRESHOLD=5
    i=0
    for log_file1 in $log_files
    do
        j=0
        for log_file2 in $log_files
        do
            # only compare to other files not itself and also compare the file later not repeat the previous already compared files
            if [ "$log_file1" != "$log_file2" ]  && [ "$j" -gt "$i" ]; then
                t1="${times[$i]}"
                t2="${times[$j]}"
                time_diff=$(expr $t1 - $t2)
                # removing -ve values if $t1 < $t2
                time_diff=${time_diff#-}
                if [ "$time_diff" -ge "$STALL_THRESHOLD" ]; then
                    echo "WARNING: stalled pipelines detected, $log_file1 and $log_file2 time difference is $time_diff seconds, above stalled threshold $STALL_THRESHOLD seconds"
                fi
            fi
            j=$((j+1))
        done
        i=$((i+1))
    done
    sleep $WATCH_POLL_INTERVAL_IN_SECOND
done

echo "log_time_monitor.sh is done"
