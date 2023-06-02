#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

gst-launch-1.0 $inputsrc ! vaapidecodebin ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 ! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log
