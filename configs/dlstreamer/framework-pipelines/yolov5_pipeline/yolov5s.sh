 #!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

DECODE="decodebin force-sw-decoders=1" #decodebin|vaapidecodebin
DEVICE="CPU" #GPU|CPU|MULTI:GPU,CPU
PRE_PROCESS="" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 
AGGREGATE="gvametaaggregate name=aggregate !" # Aggregate function at the end of the pipeline ex. "" | gvametaaggregate name=aggregate
OUTPUTFORMAT="! fpsdisplaysink video-sink=fakesink sync=true --verbose" # Output format for the pipeline  "! fpsdisplaysink video-sink=fakesink sync=true --verbose" | (render_mode)"! videoconvert ! video/x-raw,format=I420 ! gvawatermark ! videoconvert ! fpsdisplaysink video-sink=ximagesink sync=true --verbose"

echo "Run yolov5s pipeline"
gst-launch-1.0 $INPUT_SRC ! $DECODE ! gvadetect model-instance-id=odmodel name=detection model=/home/pipeline-server/models/yolov5s/FP16-INT8/1/yolov5s.xml model-proc=/home/pipeline-server/models/yolov5s/FP16-INT8/1/yolov5s.json threshold=.5 device=$DEVICE $PRE_PROCESS ! $AGGREGATE gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl $OUTPUTFORMAT 2>&1 | tee >/tmp/results/gst-launch_core_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)