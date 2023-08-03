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

DECODE="vaapidecodebin" # Input decoding method ex. decodebin force-sw-decoders=1 | vaapidecodebin   
DEVICE="CPU" # Device to run on ex. GPU | CPU | MULTI:GPU,CPU
PRE_PROCESS="" # Processess function for running on GPU ex. "" | pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1
DETECTION_OPTIONS="gpu-throughput-streams=4 nireq=4 batch-size=1" # Extra detection model parameters ex. "" | gpu-throughput-streams=4 nireq=4 batch-size=1 
CLASSIFICATION_OPTIONS="reclassify-interval=1 $DETECTION_OPTIONS" # Extra Classification model parameters ex. "" | reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4

echo "Run run yolov5s with efficientnet classification pipeline"
gst-launch-1.0 $inputsrc ! $DECODE ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=$DEVICE $PRE_PROCESS $DETECTION_OPTIONS ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=$DEVICE inference-region=roi-list name=classification $PRE_PROCESS $CLASSIFICATION_OPTIONS ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst_launch$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)