#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# test case 1: dgpu without --ocr 5
echo "test case 1: dgpu without --ocr 5 parameter"
output=$(./run.sh --platform dgpu --inputsrc rtsp://127.0.0.1:8554/camera_0 2>&1)
statusCode=$?
successCheckStr="default OCR 5 GPU"

if [ $statusCode==0 ]
then
    if grep -q "$successCheckStr" <<< "$output"; then
        echo "test PASSED: dgpu without --ocr 5 parameter set default"
    else
        echo "test FAILED: not able to set --ocr 5 GPU as default"
    fi
else
    echo "test FAILED: expecting dgpu without --ocr 5 parameter with status code 0 but got status code 1"
fi

echo 
# test case 2: dgpu with normal --ocr 10 parameter ok
echo "test case 2: dgpu with --ocr 10 parameter ok"
output=$(./run.sh --platform dgpu --inputsrc rtsp://127.0.0.1:8554/camera_0 --ocr 10 GPU 2>&1)
statusCode=$?
echo "output is: $output"

if [ $statusCode==0 ]
then
    if grep -q "$successCheckStr" <<< "$output"; then
        echo "test FAILED: got default set"
    else
        echo "test PASSED: dgpu with --ocr 10 parameter not default set"
    fi
else
    echo "test FAILED: expecting get with status code 0 but got status code 1"
fi
