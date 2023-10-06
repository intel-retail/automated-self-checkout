#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

RESULT_DIR=./results
cid_count=0

# a quick spot test script to smoke testing some of pipeline profiles
#
# setup:
setup() {
    make clean-results || true
    (
        cd ./benchmark-scripts
        ./download_sample_videos.sh
    )
    ./camera-simulator/camera-simulator.sh
}

teardown() {
    make clean-profile-launcher >/dev/null || true
    make clean-ovms >/dev/null || true
    make clean-results || true
    sleep 5
    cid_count=0
}

# $1 is the profile name
verifyStatusCode() {
    profileName=$1
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
    echo "cid_count=$cid_count"
    if [ -f "$RESULT_DIR/pipeline$cid_count.log" ] && [ -s "$RESULT_DIR/pipeline$cid_count.log" ]
    then
        echo "=== $profileName profile smoke test pipeline log PASSED"
    else
        echo "=== $profileName profile smoke test pipeline log FAILED"
    fi
}

# initial setup
setup

# 1. test profile: should run and exit without any error
cid_count=$(ps aux | grep profile-launcher | grep -v grep | wc -l)
echo "Running test profile..."
PIPELINE_PROFILE="test" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode test
teardown

# 2. classificaiton profile: should see non-empty pipeline0.log contents
make build-python-apps
cid_count=$(ps aux | grep profile-launcher | grep -v grep | wc -l)
echo "Running classification profile..."
PIPELINE_PROFILE="classification" RENDER_MODE=0 sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode classification
# allowing some time to process
sleep 40
verifyNonEmptyPipelineLog classification
teardown

#3. grpc_go profile:
make build-grpc-go
cid_count=$(ps aux | grep profile-launcher | grep -v grep | wc -l)
echo "Running grpc_go profile..."
PIPELINE_PROFILE="grpc_go" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode grpc_go
# allowing some time to process
sleep 20
verifyNonEmptyPipelineLog grpc_go
teardown

#4. grpc_python profile:
make build-grpc-python
cid_count=$(ps aux | grep profile-launcher | grep -v grep | wc -l)
echo "Running grpc_python profile..."
PIPELINE_PROFILE="grpc_python" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode grpc_python
# allowing some time to process
sleep 30
verifyNonEmptyPipelineLog grpc_python
teardown

#5. gst profile:
make build-soc
cid_count=$(ps aux | grep profile-launcher | grep -v grep | wc -l)
echo "Running gst profile..."
PIPELINE_PROFILE="gst" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode gst
# allowing some time to process
sleep 30
verifyNonEmptyPipelineLog gst
teardown

#7. instance_segmentation profile:
make build-python-apps
cid_count=$(ps aux | grep profile-launcher | grep -v grep | wc -l)
echo "Running instance_segmentation profile..."
PIPELINE_PROFILE="instance_segmentation" RENDER_MODE=0 sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
status_code=$?
verifyStatusCode instance_segmentation
# allowing some time to process
sleep 30
verifyNonEmptyPipelineLog instance_segmentation
teardown

#8. object_detection profile:
make build-python-apps
cid_count=$(ps aux | grep profile-launcher | grep -v grep | wc -l)
echo "Running object_detection profile..."
PIPELINE_PROFILE="object_detection" RENDER_MODE=0 sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_1
status_code=$?
verifyStatusCode object_detection
# allowing some time to process
sleep 30
verifyNonEmptyPipelineLog object_detection
teardown
