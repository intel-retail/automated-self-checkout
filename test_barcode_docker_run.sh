#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# test case 1: barcode missing parameter
echo "test case 1: barcode missing parameter"
./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --ocr 5 CPU --barcode
test $? -eq 1 && echo "barcode missing parameter test PASSED" || echo "test failed: expecting error with status code 1 but got status code 0"

echo 
# test case 2: barcode paramerter ok
echo "test case 2: barcode paramerter ok"
./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --ocr 5 CPU --barcode 5
test $? -eq 0 && echo "test PASSED" || echo "test failed: expecting status code 0 but got status code 1"
