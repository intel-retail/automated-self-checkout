#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

if [ "$INPUTSRC_TYPE" == "REALSENSE" ]; then
	# TODO: update with vaapipostproc when MJPEG codec is supported.
	echo "Not supported until D436 with MJPEG." > /tmp/results/pipeline$cid_count.log
	exit 2
fi

DECODE="${DECODE:="vaapidecodebin"}" # Input decoding method ex. decodebin force-sw-decoders=1 | vaapidecodebin   
DEVICE="${DEVICE:="CPU"}" #GPU|CPU|MULTI:GPU,CPU
PRE_PROCESS="${PRE_PROCESS:=""}" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1
DETECTION_OPTIONS="${DETECTION_OPTIONS:="gpu-throughput-streams=4 nireq=4 batch-size=1"}" # Extra detection model parameters ex. "" | gpu-throughput-streams=4 nireq=4 batch-size=1
CLASSIFICATION_OPTIONS="${CLASSIFICATION_OPTIONS:="reclassify-interval=1 $DETECTION_OPTIONS"}" # Extra Classification model parameters ex. "" | reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4

if [ "$RENDER_MODE" == "1" ]; then
    OUTPUT="${OUTPUT:="! videoconvert ! video/x-raw,format=I420 ! gvawatermark ! videoconvert ! fpsdisplaysink video-sink=ximagesink sync=true --verbose"}"
else
    OUTPUT="${OUTPUT:="! fpsdisplaysink video-sink=fakesink sync=true --verbose"}"
fi

echo "Run run yolov5s with efficientnet classification pipeline"
gstLaunchCmd="gst-launch-1.0 $inputsrc ! $DECODE ! gvadetect model-instance-id=odmodel name=detection model=/home/pipeline-server/models/yolov5s/FP16-INT8/1/yolov5s.xml model-proc=/home/pipeline-server/models/yolov5s/FP16-INT8/1/yolov5s.json threshold=.5 device=$DEVICE $PRE_PROCESS $DETECTION_OPTIONS ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=/home/pipeline-server/models/efficientnet-b0/1/imagenet_2012.txt model=/home/pipeline-server/models/efficientnet-b0/FP32-INT8/1/efficientnet-b0.xml model-proc=/home/pipeline-server/models/efficientnet-b0/efficientnet-b0.json device=$DEVICE inference-region=roi-list name=classification $PRE_PROCESS $CLASSIFICATION_OPTIONS ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl $OUTPUT 2>&1 | tee >/tmp/results/gst_launch$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)"

echo "$gstLaunchCmd"

eval $gstLaunchCmd