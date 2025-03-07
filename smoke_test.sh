#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#


RESULT_DIR=./results

# a quick spot test script to smoke testing some of pipeline profiles
#
# setup:
setup() {
    echo "Clean existing Docker containers"
    make clean-all || true
    echo "Build Automated Self Checkout image"
    make build
}

teardown() {
    make down
    make clean-results || true
}

# $1 is the profile name
# $2 is the status code from caller
verifyStatusCode() {
    status_code=$1
    if [ "$status_code" -eq 0 ]
    then
        echo "=== Automated Self Checkout smoke test status code PASSED"
    else
        echo "=== Automated Self Checkout smoke test status code FAILED"
    fi
}

# $1 is the profile name
verifyNonEmptyPipelineLog() {
    if [ $(ls $RESULT_DIR/pipeline*.log 2> /dev/null | wc -l) -ge 1 ]
    then
        echo "=== Automated Self Checkout smoke test pipeline log PASSED"
    else
        echo "=== Automated Self Checkout smoke test pipeline log FAILED"
    fi
}

waitForLogFile() {
    max_wait_time=300
    sleep_increments=10
    total_wait_time=0
    pipeline_logs=0
    echo "Waiting for log file to generate"
    while [ $pipeline_logs -le 0 ]
    do
        pipeline_logs=$(ls $RESULT_DIR/pipeline*.log 2> /dev/null | wc -l)
        echo $pipeline_logs
        ls $RESULT_DIR/pipeline*.log 2> /dev/null | wc -l
        if [ "$total_wait_time" -gt "$max_wait_time" ]
        then
            echo "FAILED: exceeding the max wait time $max_wait_time while waiting for pipeline0.log file, stop waiting"
            return
        fi
        echo "could not find pipeline log file yet, sleep for $sleep_increments and retry it again"
        sleep $sleep_increments
        total_wait_time=$(( total_wait_time + sleep_increments ))
    done
    echo "total wait time = $total_wait_time seconds"
}

# initial setup
setup

# 1. test Automated Self Checkout: should run and exit without any error
echo "Running Automated Self Checkout..."
make run
status_code=$?
verifyStatusCode $status_code
# test profile currently doesn't have logfile output
teardown

# 2. Automated Self Checkout CPU results: should see non-empty pipeline0.log contents
echo "Running Automated Self Checkout CPU with logs..."
make run
status_code=$?
verifyStatusCode $status_code 
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog
teardown

MODEL=${1:-yolov5}

# 3. Automated Self Checkout GPU results: should see non-empty pipeline0.log contents
echo "Running Automated Self Checkout GPU using ${MODEL} with logs..."
make run DEVICE_ENV=res/all-gpu.env DEVICE=GPU
status_code=$?
verifyStatusCode $status_code 
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog
teardown

if [ "$1" = "yolov8" ]; then
    # 4. Yolov8s pipeine: should see non-empty pipeline0.log contents
    echo "Running YOLOv8s pipeline with logs..."
    INPUTSRC=https://github.com/intel-iot-devkit/sample-videos/raw/master/people-detection.mp4 PIPELINE_SCRIPT=yolov8s_roi.sh docker compose -f src/docker-compose.yml up -d
    status_code=$?
    verifyStatusCode $status_code 
    # allowing some time to process
    waitForLogFile
    verifyNonEmptyPipelineLog
    teardown

    # 5. Age pipeline: should see non-empty pipeline0.log contents
    echo "Running Age Classification pipeline with logs..."
    INPUTSRC=https://www.pexels.com/download/video/3248275 PIPELINE_SCRIPT=age_recognition.sh docker compose -f src/docker-compose.yml up -d
    status_code=$?
    verifyStatusCode $status_code 
    # allowing some time to process
    waitForLogFile
    verifyNonEmptyPipelineLog
    teardown
fi





