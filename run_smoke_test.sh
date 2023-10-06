#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

RESULT_DIR=./results

# a quick spot test script to smoke testing some of pipeline profiles
#
# setup:
setup() {
    make clean-all || true
    (
        cd ./benchmark-scripts
        ./download_sample_videos.sh
    )
    ./camera-simulator/camera-simulator.sh
}

teardown() {
    make clean-profile-launcher >/dev/null || true
    # we should make sure the pl_count = 0 before contiues
    pl_count=$(ps aux | grep profile-launcher | grep -v grep | wc -l)
    MAX_RETRY=100
    retry_cnt=0
    while [ "$pl_count" -gt 0 ]
    do
        if [ "$retry_cnt" -gt 100 ]
        then
            echo "FAILED: cannot kill profile-launcher process after $MAX_RETRY"
            return
        fi
        echo "waiting a bit longer..."
        sleep 1
        pl_count=$(ps aux | grep profile-launcher | grep -v grep | wc -l)
        retry_cnt=$(( retry_cnt + 1 ))
    done
    make clean-ovms >/dev/null || true
    make clean-results || true
}

# $1 is the profile name
# $2 is the status code from caller
verifyStatusCode() {
    profileName=$1
    status_code=$2
    if [ "$status_code" -eq 0 ]
    then
        echo "=== $profileName profile smoke test status code PASSED"
    else
        echo "=== $profileName profile smoke test status code FAILED"
    fi
}

# $1 is the profile name
verifyNonEmptyPipelineLog() {
    profileName=$1
    if [ -f "$RESULT_DIR/pipeline0.log" ] && [ -s "$RESULT_DIR/pipeline0.log" ]
    then
        echo "=== $profileName profile smoke test pipeline log PASSED"
    else
        echo "=== $profileName profile smoke test pipeline log FAILED"
    fi
}

waitForLogFile() {
    max_wait_time=1000
    sleep_increments=10
    total_wait_time=0
    while [ ! -f "$RESULT_DIR/pipeline0.log" ] || [ ! -s "$RESULT_DIR/pipeline0.log" ]
    do
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

# 1. test profile: should run and exit without any error
echo "Running test profile..."
PIPELINE_PROFILE="test" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode test $status_code
# test profile currently doesn't have logfile output
teardown

# 2. classificaiton profile: should see non-empty pipeline0.log contents
make build-python-apps
echo "Running classification profile..."
PIPELINE_PROFILE="classification" RENDER_MODE=0 sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode classification $status_code
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog classification
teardown

#3. grpc_go profile:
make build-grpc-go
echo "Running grpc_go profile..."
PIPELINE_PROFILE="grpc_go" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode grpc_go $status_code
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog grpc_go
teardown

#4. grpc_python profile:
make build-grpc-python
echo "Running grpc_python profile..."
PIPELINE_PROFILE="grpc_python" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode grpc_python $status_code
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog grpc_python
teardown

#5. gst profile:
make build-soc
echo "Running gst profile..."
PIPELINE_PROFILE="gst" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode gst $status_code
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog gst
teardown

#6. instance_segmentation profile:
make build-python-apps
echo "Running instance_segmentation profile..."
PIPELINE_PROFILE="instance_segmentation" RENDER_MODE=0 sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode instance_segmentation $status_code
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog instance_segmentation
teardown

#7. object_detection profile:
make build-python-apps
echo "Running object_detection profile..."
PIPELINE_PROFILE="object_detection" RENDER_MODE=0 sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_1
status_code=$?
verifyStatusCode object_detection $status_code
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog object_detection
teardown
