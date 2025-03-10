 #!/bin/bash
#
# Copyright (C) 2025 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

PRE_PROCESS="${PRE_PROCESS:=""}" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 
AGGREGATE="${AGGREGATE:="gvametaaggregate name=aggregate !"}" # Aggregate function at the end of the pipeline ex. "" | gvametaaggregate name=aggregate
PUBLISH="${PUBLISH:="name=destination file-format=2 file-path=/tmp/results/r$cid.jsonl"}" # address=localhost:1883 topic=inferenceEvent method=mqtt

CLASS_IDS="46,39,47" # YOLOv8 classes to be detected example "0,1,30"

if [ "$RENDER_MODE" == "1" ] && [ "$RTSP" == "0" ]; then
    OUTPUT="${OUTPUT:="! videoconvert ! gvawatermark ! videoconvert ! fpsdisplaysink video-sink=ximagesink sync=true --verbose"}"
fi

if [ "$RENDER_MODE" == "0" ] && [ "$RTSP" == "0" ]; then
    OUTPUT="${OUTPUT:="! fpsdisplaysink video-sink=fakesink sync=true --verbose"}"
fi

if [ "$RTSP" == "1" ]; then
    OUTPUT="${OUTPUT:="! gvawatermark ! videoscale ! video/x-raw,width=1280,height=720,pixel-aspect-ratio=1/1 ! videocrop left=10 right=10 ! queue max-size-buffers=1 max-size-bytes=0 max-size-time=0 ! x264enc speed-preset=medium tune=zerolatency key-int-max=1 bitrate=8000 quantizer=10 ! video/x-h264, profile=high ! rtspclientsink location=rtsp://localhost:8554/yolo"}"
fi

echo "decode type $DECODE"
echo "Run YOLOv8 pipeline on $DEVICE with batch size = $BATCH_SIZE"

gstLaunchCmd="GST_DEBUG=1 GST_TRACERS=\"latency_tracer(flags=pipeline,interval=100)\" gst-launch-1.0 $inputsrc ! $DECODE ! gvadetect batch-size=$BATCH_SIZE model-instance-id=odmodel name=detection model=models/object_detection/yolov8s/FP32/yolov8s.xml device=$DEVICE $PRE_PROCESS inference-region=1 object-class="$CLASS_IDS" threshold=0.6 ! \
gvapython module=/home/pipeline-server/extensions/object_filter.py class=ObjectDetectionFilter kwarg=\"{\\\"class_ids\\\": \\\"$CLASS_IDS\\\"}\" !  gvatrack ! \
$AGGREGATE gvametaconvert name=metaconvert add-empty-results=true ! \
queue ! \
gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid.jsonl $OUTPUT 2>&1 | tee >/tmp/results/gst-launch_$cid.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid.log)"


echo "$gstLaunchCmd"

eval $gstLaunchCmd