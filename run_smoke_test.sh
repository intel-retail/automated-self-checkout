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
        if [ "$retry_cnt" -gt "$MAX_RETRY" ]
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
    input_src=$3
    if [ "$status_code" -eq 0 ]
    then
        echo "=== $profileName $input_src profile smoke test status code PASSED"
    else
        echo "=== $profileName $input_src profile smoke test status code FAILED"
    fi
}

# $1 is the profile name
verifyNonEmptyPipelineLog() {
    profileName=$1
    input_src=$2
    if [ -f "$RESULT_DIR/pipeline0.log" ] && [ -s "$RESULT_DIR/pipeline0.log" ]
    then
        echo "=== $profileName $input_src profile smoke test pipeline log PASSED"
    else
        echo "=== $profileName $input_src profile smoke test pipeline log FAILED"
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
test_input_src="rtsp://127.0.0.1:8554/camera_0"
PIPELINE_PROFILE="test" sudo -E ./run.sh --workload ovms --platform core --inputsrc "$test_input_src"
status_code=$?
verifyStatusCode test $status_code $test_input_src
# test profile currently doesn't have logfile output
teardown

# 2. classificaiton profile: should see non-empty pipeline0.log contents
make build-python-apps
echo "Running classification profile..."
classification_input_src="rtsp://127.0.0.1:8554/camera_0"
PIPELINE_PROFILE="classification" RENDER_MODE=0 sudo -E ./run.sh --workload ovms --platform core --inputsrc "$classification_input_src"
status_code=$?
verifyStatusCode classification $status_code $classification_input_src
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog classification $classification_input_src
teardown

#3. grpc_go profile:
make build-grpc-go
echo "Running grpc_go profile..."
grpc_go_input_src="rtsp://127.0.0.1:8554/camera_0"
PIPELINE_PROFILE="grpc_go" sudo -E ./run.sh --workload ovms --platform core --inputsrc "$grpc_go_input_src"
status_code=$?
verifyStatusCode grpc_go $status_code $grpc_go_input_src
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog grpc_go $grpc_go_input_src
teardown

#4. grpc_python profile:
make build-grpc-python
echo "Running grpc_python profile..."
grpc_python_input_src="rtsp://127.0.0.1:8554/camera_0"
PIPELINE_PROFILE="grpc_python" sudo -E ./run.sh --workload ovms --platform core --inputsrc "$grpc_python_input_src"
status_code=$?
verifyStatusCode grpc_python $status_code $grpc_python_input_src
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog grpc_python $grpc_python_input_src
teardown

#5. gst profile:
# gst RTSP
make build-dlstreamer
echo "Running gst profile..."
gst_rtsp_input_src="rtsp://127.0.0.1:8554/camera_0"
PIPELINE_PROFILE="gst" sudo -E ./run.sh --workload ovms --platform core --inputsrc "$gst_rtsp_input_src"
status_code=$?
verifyStatusCode gst $status_code $gst_rtsp_input_src
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog gst $gst_rtsp_input_src
teardown

# gst realsense, hardware dependency: gst_realsense_input_src requires realsense serial number
make build-dlstreamer-realsense
realsenseSerialNum=$(./get-realsense-serialno.sh)
echo "realsenseSerialNum: $realsenseSerialNum"
realsenseSerialNum="${realsenseSerialNum//[$'\t\r\n']}"
numberRegex="[[:digit:]]+"
aNum=$(echo "$realsenseSerialNum" | grep -Eo "$numberRegex")
if [[ -n "$aNum" ]]
then
    echo "Running gst profile with realsenseSerialNum: $realsenseSerialNum"
    PIPELINE_PROFILE="gst" sudo -E ./run.sh --workload ovms --platform core --inputsrc "$realsenseSerialNum"
    status_code=$?
    verifyStatusCode gst "$status_code" "$realsenseSerialNum"
    if [ "$status_code" -eq 0 ]
    then
        # allowing some time to process
        waitForLogFile
        verifyNonEmptyPipelineLog gst "$realsenseSerialNum"
    fi
    teardown
else
    echo "No RealSense camera found, skip."
fi

# # gst video, hardware dependency: make sure there is USB camera plugged in
# gst_video_input_src="/dev/video2"
# PIPELINE_PROFILE="gst" sudo -E ./run.sh --workload ovms --platform core --inputsrc "$gst_video_input_src"
# status_code=$?
# verifyStatusCode gst $status_code $gst_video_input_src
# # allowing some time to process
# waitForLogFile
# verifyNonEmptyPipelineLog gst $gst_video_input_src
# teardown

# # gst from file, make sure the mp4 file has been downloaded
# gst_file_input_src="file:coca-cola-4465029-3840-15-bench.mp4"
# PIPELINE_PROFILE="gst" sudo -E ./run.sh --workload ovms --platform core --inputsrc "$gst_file_input_src"
# status_code=$?
# verifyStatusCode gst $status_code $gst_file_input_src
# # allowing some time to process
# waitForLogFile
# verifyNonEmptyPipelineLog gst $gst_file_input_src
# teardown

#6. instance_segmentation profile:
make build-python-apps
echo "Running instance_segmentation profile..."
is_input_src="rtsp://127.0.0.1:8554/camera_0"
PIPELINE_PROFILE="instance_segmentation" RENDER_MODE=0 sudo -E ./run.sh --workload ovms --platform core --inputsrc "$is_input_src"
status_code=$?
verifyStatusCode instance_segmentation $status_code $is_input_src
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog instance_segmentation $is_input_src
teardown

#7. object_detection profile:
make build-python-apps
echo "Running object_detection profile..."
od_input_src="rtsp://127.0.0.1:8554/camera_1"
PIPELINE_PROFILE="object_detection" RENDER_MODE=0 sudo -E ./run.sh --workload ovms --platform core --inputsrc "$od_input_src"
status_code=$?
verifyStatusCode object_detection $status_code $od_input_src
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog object_detection $od_input_src
teardown

#8. gst capi capi_face_detection profile:
make build-capi_face_detection
echo "Running capi_face_detection profile..."
input_src="rtsp://127.0.0.1:8554/camera_1"
PIPELINE_PROFILE="capi_face_detection" RENDER_MODE=0 sudo -E ./run.sh --workload ovms --platform core --inputsrc "$input_src"
status_code=$?
verifyStatusCode capi_face_detection $status_code $input_src
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog capi_face_detection $input_src
teardown

#9. gst capi capi_yolov5 profile:
make build-capi_yolov5
echo "Running capi_yolov5 profile..."
input_src="rtsp://127.0.0.1:8554/camera_1"
PIPELINE_PROFILE="capi_yolov5" RENDER_MODE=0 sudo -E ./run.sh --workload ovms --platform core --inputsrc "$input_src"
status_code=$?
verifyStatusCode capi_yolov5 $status_code $input_src
# allowing some time to process
waitForLogFile
verifyNonEmptyPipelineLog capi_yolov5 $input_src
teardown