#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

PRE_PROCESS="${PRE_PROCESS:=""}" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 
AGGREGATE="${AGGREGATE:="gvametaaggregate name=aggregate !"}" # Aggregate function at the end of the pipeline ex. "" | gvametaaggregate name=aggregate
PUBLISH="${PUBLISH:="name=destination file-format=2 file-path=/tmp/results/r$cid.jsonl"}" # address=localhost:1883 topic=inferenceEvent method=mqtt

CLASSIFICATION_OPTIONS="${CLASSIFICATION_OPTIONS:="reclassify-interval=1 $DETECTION_OPTIONS"}" # Extra Classification model parameters ex. "" | reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4

if [ "$RENDER_MODE" == "1" ]; then
    OUTPUT="${OUTPUT:="! videoconvert ! video/x-raw,format=I420 ! gvawatermark ! videoconvert ! fpsdisplaysink video-sink=ximagesink sync=true --verbose"}"
else
    OUTPUT="${OUTPUT:="! fpsdisplaysink video-sink=fakesink sync=true --verbose"}"
fi

echo "decode type $DECODE"
echo "Run age_recognition pipeline on $DEVICE with batch size = $BATCH_SIZE"

DETECT_MODEL_PATH="models/object_detection/face-detection-retail-0005/FP16-INT8/face-detection-retail-0005.xml"

CLASS_MODEL_PATH="models/object_classification/age-gender-recognition-retail-0013/FP16-INT8/age-gender-recognition-retail-0013.xml"
CLASS_MODEL_PROC_PATH="models/object_classification/age-gender-recognition-retail-0013/age-gender-recognition-retail-0013.json"

gstLaunchCmd="gst-launch-1.0 $inputsrc ! $DECODE ! \
gvadetect batch-size=$BATCH_SIZE model-instance-id=odmodel name=detection model=$DETECT_MODEL_PATH threshold=.8 device=$DEVICE ! \
gvaclassify batch-size=$BATCH_SIZE model-instance-id=classifier name=recognition model-proc=$CLASS_MODEL_PROC_PATH model=$CLASS_MODEL_PATH device=$DEVICE $CLASSIFICATION_OPTIONS ! \
$AGGREGATE gvametaconvert name=metaconvert add-empty-results=true ! \
gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid.jsonl $OUTPUT 2>&1 | tee >/tmp/results/gst-launch_$cid.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid.log)"

echo "$gstLaunchCmd"

eval $gstLaunchCmd
