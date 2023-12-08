#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

checkNumOfPipelineLogFiles(){
    RESULT_DIR="../results"
    expectedNumOfNonEmptyLogs=2
    numFoundLogs=0
    # check non-empty pipeline logs- should find 2
    for i in $( seq 0 $(( expectedNumOfNonEmptyLogs-1 )))
    do
        if [ -f "$RESULT_DIR/pipeline$i.log" ] && [ -s "$RESULT_DIR/pipeline$i.log" ]
        then
            echo "found non-empty pipeline$i.log file"
            numFoundLogs=$(( numFoundLogs + 1 ))
        else
            echo "could not find non-empty pipeline$i.log file"
        fi
    done

    if [ "$numFoundLogs" -ne "$expectedNumOfNonEmptyLogs" ]
    then
        echo "test for benchmarking multiple pipeline profile $PIPELINE_PROFILE FAILED: expect to have $expectedNumOfNonEmptyLogs pipelines but found $numFoundLogs"
    else
        echo "test for benchmarking multiple pipeline $PIPELINE_PROFILE PASSED: there are exactly $expectedNumOfNonEmptyLogs pipelines"
    fi
}

# inital setup
(
    cd ..
    make clean-all
    sleep 3
    make build-python-apps
    make build-capi_yolov5
)

 ./download_sample_videos.sh

# test for non-capi objec_detection
PIPELINE_PROFILE="object_detection" RENDER_MODE=0 sudo -E ./benchmark.sh --pipelines 2 --logdir test_object_detection/data --duration 30 --init_duration 10  --platform core --inputsrc rtsp://127.0.0.1:8554/camera_1
sleep 2
PIPELINE_PROFILE="object_detection"; checkNumOfPipelineLogFiles > testbenchmark.log

#clean up
sudo rm -rf test_object_detection/
(
    cd ..
    make clean-all
)

# test for capi-yolov5
PIPELINE_PROFILE="capi_yolov5" RENDER_MODE=0 sudo -E ./benchmark.sh --pipelines 2 --logdir test_capi_yolov5/data --duration 30 --init_duration 10  --platform core --inputsrc rtsp://127.0.0.1:8554/camera_1
sleep 2
PIPELINE_PROFILE="capi_yolov5"; checkNumOfPipelineLogFiles >> testbenchmark.log

#clean up
sudo rm -rf test_capi_yolov5/
(
    cd ..
    make clean-all
)

# show test results:
grep --color=never "test for benchmarking multiple pipeline" testbenchmark.log
rm testbenchmark.log
