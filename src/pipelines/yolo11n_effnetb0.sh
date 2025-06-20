#!/bin/bash
#
# Copyright (C) 2025 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

if [ "$INPUTSRC_TYPE" == "REALSENSE" ]; then
	# TODO: update with vaapipostproc when MJPEG codec is supported.
	echo "Not supported until D436 with MJPEG." > /tmp/results/pipeline$cid.log
	exit 2
fi

RTSP_PATH=${RTSP_PATH:="output_$cid"}
CLASSIFICATION_DEVICE="${CLASSIFICATION_DEVICE:=$DEVICE}"
PRE_PROCESS="${PRE_PROCESS:=""}" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1

if [ "$RENDER_MODE" == "1" ]; then
    OUTPUT="gvawatermark ! videoconvert ! fpsdisplaysink video-sink="autovideosink" text-overlay=false signal-fps-measurements=true"
elif [ "$RTSP_OUTPUT" == "1" ]; then
    OUTPUT="gvawatermark ! x264enc ! video/x-h264,profile=baseline ! rtspclientsink location=$RTSP_SERVER/$RTSP_PATH protocols=tcp timeout=0"
else
    OUTPUT="fpsdisplaysink video-sink=fakesink signal-fps-measurements=true"
fi

echo "Run run yolo11n with efficientnet classification pipeline on $DEVICE with batch size = $BATCH_SIZE"

gstLaunchCmd="gst-launch-1.0 --verbose \
    $inputsrc ! $DECODE \
    ! queue \
    ! gvadetect batch-size=$BATCH_SIZE \
        model-instance-id=odmodel \
        name=detection \
        model=/home/pipeline-server/models/object_detection/yolo11n/FP16/yolo11n.xml \
        threshold=0.5 \
        device=$DEVICE \
        $PRE_PROCESS $DETECTION_OPTIONS \
    ! queue \
    ! gvatrack \
        name=tracking \
        tracking-type=zero-term-imageless \
    ! queue \
    ! gvaclassify batch-size=$BATCH_SIZE \
        model-instance-id=classifier \
        labels=/home/pipeline-server/models/object_classification/efficientnet-b0/imagenet_2012.txt \
        model=/home/pipeline-server/models/object_classification/efficientnet-b0/FP32/efficientnet-b0.xml \
        model-proc=/home/pipeline-server/models/object_classification/efficientnet-b0/efficientnet-b0.json \
        device=$CLASSIFICATION_DEVICE \
        name=classification \
        $CLASSIFICATION_PRE_PROCESS $CLASSIFICATION_OPTIONS \
    ! gvametaconvert \
    ! tee name=t \
        t. ! queue ! $OUTPUT \
        t. ! queue ! gvametapublish name=destination file-format=json-lines file-path=/tmp/results/r\$cid.jsonl ! fakesink sync=false async=false \
    2>&1 | tee /tmp/results/gst-launch_\$cid.log \
    | (stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline\$cid.log)"

echo "$gstLaunchCmd"

eval $gstLaunchCmd
