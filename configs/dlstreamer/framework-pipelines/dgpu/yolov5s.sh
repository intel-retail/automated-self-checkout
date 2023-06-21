#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

if [ "$AUTO_SCALE_FLEX_140" == "1" ]
then
        deviceid=$(($cid_count % 2))
        if [ "$deviceid" == "0" ]
        then
                GST_VAAPI_DRM_DEVICE=/dev/dri/renderD128
        else
                GST_VAAPI_DRM_DEVICE=/dev/dri/renderD129
        fi
	export GST_VAAPI_DRM_DEVICE="$GST_VAAPI_DRM_DEVICE"
fi

gst-launch-1.0 $inputsrc ! vaapidecodebin ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 ! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst-launch_dgpu$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
