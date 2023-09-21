#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

cleanup()
{
    ./stop_all_docker_containers.sh
    sleep 2
    sudo rm -rf ./results/*.log
    sudo rm -rf ./results/*.jsonl
}

REAL_SENSE_SERIAL_NUM=$1

if [ -z "$REAL_SENSE_SERIAL_NUM" ]; then
    echo "please provide realsense serial number as input"
    exit 1
fi

# test case 1: input param color-width=1280
cleanup
expectedColorWidth=1280
echo "test case 1: input param color-width=$expectedColorWidth"
./run.sh --platform core --inputsrc "$REAL_SENSE_SERIAL_NUM" --realsense_enabled --color-width "$expectedColorWidth"
exitCode=$?
if [ "$exitCode" != 0 ]; then
    echo "run.sh exited with status code $exitCode"
    exit 1
fi

echo "waiting for settling down..."
sleep 30
fps_output=$(grep . ./results/pipeline0.log | tail -1)
if [ -z "$fps_output" ]; then
    echo "test failed: no fps output from the log"
else
    colorWidthOut=$(grep -Eo '("resolution":{"height":[[:digit:]]+,"width":[[:digit:]]+)' ./results/r0.jsonl | awk -F ':' '{print $4}' | tail -1)
    if [ -z "$colorWidthOut" ]; then
        echo "test failed: no width output found from the r0.jsonl"
    elif [ "$expectedColorWidth" -ne "$colorWidthOut" ]; then
        echo "test failed: the color width output $colorWidthOut is different from the expected width $expectedColorWidth"
    else
        echo "test passed; found color width $colorWidthOut"
    fi
fi

echo 

# test case 2: input param color-height=720
cleanup
expectedColorHeight=720
echo "test case 2: input param color-height=$expectedColorHeight"
./run.sh --platform core --inputsrc "$REAL_SENSE_SERIAL_NUM" --realsense_enabled --color-height "$expectedColorHeight"
exitCode=$?
if [ "$exitCode" != 0 ]; then
    echo "run.sh exited with status code $exitCode"
    exit 1
fi
echo "waiting for settling down..."
sleep 30
fps_output=$(grep . ./results/pipeline0.log | tail -1)
if [ -z "$fps_output" ]; then
    echo "test failed: no fps output from the log"
else
    colorHeightOut=$(grep -Eo '("resolution":{"height":[[:digit:]]+,)' ./results/r0.jsonl | awk -F ':' '{print $3}' | tail -1)
    if [ -z "$colorHeightOut" ]; then
        echo "test failed: no height output found from the r0.jsonl"
    elif [ "$expectedColorHeight" -ne "$colorHeightOut" ]; then
        echo "test failed: the color height output $colorHeightOut is different from the expected height $expectedColorHeight"
    else
        echo "test passed; found color height $colorHeightOut"
    fi
fi

echo 

# test case 3: input param color-framerate=30
cleanup
expectedColorFramerate=30
echo "test case 3: input param color-framerate=$expectedColorFramerate"
./run.sh --platform core --inputsrc "$REAL_SENSE_SERIAL_NUM" --realsense_enabled --color-framerate "$expectedColorFramerate"
exitCode=$?
if [ "$exitCode" != 0 ]; then
    echo "run.sh exited with status code $exitCode"
    exit 1
fi
echo "waiting for settling down..."
sleep 30
fps_output=$(grep . ./results/pipeline0.log | tail -1)
if [ -z "$fps_output" ]; then
    echo "test failed: no fps output from the log"
else
    echo "test passed: found fps output from the log"
fi


# tear down
cleanup
