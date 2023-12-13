 #!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

DECODE="${DECODE:="decodebin force-sw-decoders=1"}" #decodebin|vaapidecodebin
DEVICE="${DEVICE:="CPU"}" #GPU|CPU|MULTI:GPU,CPU
PRE_PROCESS="${PRE_PROCESS:=""}" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 
AGGREGATE="${AGGREGATE:="gvametaaggregate name=aggregate !"}" # Aggregate function at the end of the pipeline ex. "" | gvametaaggregate name=aggregate

if [ "$RENDER_MODE" == "1" ]; then
    OUTPUT="${OUTPUT:="! videoconvert ! video/x-raw,format=I420 ! gvawatermark ! videoconvert ! fpsdisplaysink video-sink=ximagesink sync=true --verbose"}"
else
    OUTPUT="${OUTPUT:="! fpsdisplaysink video-sink=fakesink sync=true --verbose"}"
fi

echo "Run yolov5s pipeline"

gstLaunchCmd="GST_DEBUG=\"GST_TRACER:7\" GST_TRACERS=\"latency_tracer(flags=pipeline,interval=100)\" gst-launch-1.0 $inputsrc ! $DECODE ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/FP16-INT8/1/yolov5s.xml model-proc=models/yolov5s/FP16-INT8/1/yolov5s.json threshold=.5 device=$DEVICE $PRE_PROCESS ! $AGGREGATE gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl $OUTPUT 2>&1 | tee >/tmp/results/gst-launch_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)"

echo "$gstLaunchCmd"

eval $gstLaunchCmd
