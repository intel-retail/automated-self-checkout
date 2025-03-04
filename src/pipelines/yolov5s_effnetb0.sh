#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

if [ "$INPUTSRC_TYPE" == "REALSENSE" ]; then
	# TODO: update with vaapipostproc when MJPEG codec is supported.
	echo "Not supported until D436 with MJPEG." > /tmp/results/pipeline$cid.log
	exit 2
fi

CLASSIFICATION_DEVICE="${CLASSIFICATION_DEVICE:=$DEVICE}"
PRE_PROCESS="${PRE_PROCESS:=""}" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1
DETECTION_OPTIONS="${DETECTION_OPTIONS:="gpu-throughput-streams=4 nireq=4 batch-size=1"}" # Extra detection model parameters ex. "" | gpu-throughput-streams=4 nireq=4 batch-size=1

CLASSIFICATION_OPTIONS="${CLASSIFICATION_OPTIONS:="reclassify-interval=1 $DETECTION_OPTIONS"}" # Extra Classification model parameters ex. "" | reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4

PUBLISH="${PUBLISH:="name=destination file-format=2 file-path=/tmp/results/r$cid.jsonl"}" # address=localhost:1883 topic=inferenceEvent method=mqtt

if [ "$RENDER_MODE" == "1" ]; then
    OUTPUT="${OUTPUT:="! videoconvert ! video/x-raw,format=I420 ! gvawatermark ! videoconvert ! fpsdisplaysink video-sink=ximagesink sync=true --verbose"}"
else
    OUTPUT="${OUTPUT:="! fpsdisplaysink video-sink=fakesink sync=true --verbose"}"
fi

echo "Run run yolov5s with efficientnet classification pipeline on $DEVICE with batch size = $BATCH_SIZE"

gstLaunchCmd="gst-launch-1.0 $inputsrc ! $DECODE ! gvadetect batch-size=$BATCH_SIZE model-instance-id=odmodel name=detection model=/home/pipeline-server/models/object_detection/yolov5s/FP16-INT8/yolov5s.xml model-proc=/home/pipeline-server/models/object_detection/yolov5s/yolov5s.json threshold=.5 device=$DEVICE $PRE_PROCESS $DETECTION_OPTIONS ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=/home/pipeline-server/models/object_classification/efficientnet-b0/imagenet_2012.txt model=/home/pipeline-server/models/object_classification/efficientnet-b0/FP32/efficientnet-b0.xml model-proc=/home/pipeline-server/models/object_classification/efficientnet-b0/efficientnet-b0.json device=$CLASSIFICATION_DEVICE inference-region=roi-list name=classification $CLASSIFICATION_PRE_PROCESS $CLASSIFICATION_OPTIONS ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid.jsonl $OUTPUT 2>&1 | tee >/tmp/results/gst-launch_$cid.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid.log)"

echo "$gstLaunchCmd"

eval $gstLaunchCmd