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

PRE_PROCESS="${PRE_PROCESS:=""}" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1
DETECTION_OPTIONS="${DETECTION_OPTIONS:="gpu-throughput-streams=4 nireq=4"}" # Extra detection model parameters ex. "" | gpu-throughput-streams=4 nireq=4 batch-size=1

if [ "$RENDER_MODE" == "1" ]; then
    OUTPUT="gvawatermark ! videoconvert ! fpsdisplaysink video-sink=autovideosink text-overlay=false sync=true signal-fps-measurements=true"
else
    OUTPUT="fpsdisplaysink video-sink=fakesink sync=true signal-fps-measurements=true"
fi

echo "Run run yolov5s pipeline on $DEVICE with batch size = $BATCH_SIZE"

gstLaunchCmd="gst-launch-1.0 --verbose \
    $inputsrc ! $DECODE \
    ! gvadetect batch-size=$BATCH_SIZE \
        model-instance-id=odmodel \
        name=detection \
        model=/home/pipeline-server/models/object_detection/yolov5s/FP16-INT8/yolov5s.xml \
        model-proc=/home/pipeline-server/models/object_detection/yolov5s/yolov5s.json \
        threshold=0.5 \
        device=$DEVICE \
        $PRE_PROCESS $DETECTION_OPTIONS \
    ! gvametaconvert \
    ! tee name=t \
        t. ! queue ! $OUTPUT \
        t. ! queue ! gvametapublish name=destination file-format=json-lines file-path=/tmp/results/r\$cid.jsonl ! fakesink async=false \
    2>&1 | tee /tmp/results/gst-launch_\$cid.log \
    | (stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline\$cid.log)"

echo "$gstLaunchCmd"

eval $gstLaunchCmd