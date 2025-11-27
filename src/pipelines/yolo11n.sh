#!/bin/bash
#
# Copyright (C) 2025 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#
set -eo pipefail
if [ "$INPUTSRC_TYPE" == "REALSENSE" ]; then
	# TODO: update with vaapipostproc when MJPEG codec is supported.
	echo "Not supported until D436 with MJPEG." > /tmp/results/pipeline$cid.log
	exit 2
fi

RTSP_PATH=${RTSP_PATH:="output_$cid"}

PRE_PROCESS="${PRE_PROCESS:=""}" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1

# Queue optimization for low latency
# Set LOW_LATENCY=1 to reduce queue sizes and minimize end-to-end latency (aggressive)
# Set MEDIUM_LATENCY=1 for production-realistic settings (balanced latency vs robustness)
# Set DROP_OLD_FRAMES=1 to always process most recent frames (drops old frames when queue is full)
if [ "$LOW_LATENCY" == "1" ]; then
    if [ "$DROP_OLD_FRAMES" == "1" ]; then
        QUEUE_PARAMS="max-size-buffers=3 max-size-time=100000000 leaky=downstream"
        echo "LOW-LATENCY MODE + DROP OLD FRAMES: Always processing most recent frames (max-size-buffers=3, leaky=downstream)"
    else
        QUEUE_PARAMS="max-size-buffers=3 max-size-time=100000000"
        echo "LOW-LATENCY MODE: Queue sizes optimized (max-size-buffers=3, max-size-time=0.1s)"
    fi
elif [ "$MEDIUM_LATENCY" == "1" ]; then
    if [ "$DROP_OLD_FRAMES" == "1" ]; then
        QUEUE_PARAMS="max-size-buffers=10 max-size-time=500000000 leaky=downstream"
        echo "MEDIUM-LATENCY MODE + DROP OLD FRAMES: Always processing most recent frames (max-size-buffers=10, max-size-time=0.5s, leaky=downstream)"
    else
        QUEUE_PARAMS="max-size-buffers=10 max-size-time=500000000"
        echo "MEDIUM-LATENCY MODE: Production-realistic queue sizes (max-size-buffers=10, max-size-time=0.5s)"
    fi
else
    QUEUE_PARAMS=""
    echo "STANDARD MODE: Using default queue sizes"
fi

# Inference interval optimization
# Set INFERENCE_INTERVAL to control frame processing (default=3, 1=every frame)
echo "INFERENCE INTERVAL: Processing every ${INFERENCE_INTERVAL} frame(s)"


if [ "$RENDER_MODE" == "1" ]; then
    OUTPUT="gvawatermark ! videoconvert ! fpsdisplaysink video-sink=autovideosink text-overlay=false signal-fps-measurements=true"
elif [ "$RTSP_OUTPUT" == "1" ]; then
    OUTPUT="gvawatermark ! x264enc ! video/x-h264,profile=baseline ! rtspclientsink location=$RTSP_SERVER/$RTSP_PATH protocols=tcp timeout=0"
else
    OUTPUT="fpsdisplaysink video-sink=fakesink signal-fps-measurements=true"
fi

echo "Run run yolo11s pipeline on $DEVICE with detection batch size = $BATCH_SIZE_DETECT"

gstLaunchCmd="GST_DEBUG="GST_TRACER:7" GST_TRACERS='latency_tracer(flags=pipeline)' gst-launch-1.0 --verbose \
    $inputsrc ! $DECODE \
    ! queue $QUEUE_PARAMS \
    ! gvadetect batch-size=$BATCH_SIZE_DETECT \
        model-instance-id=odmodel \
        name=detection \
        model=/home/pipeline-server/models/object_detection/yolo11n/INT8/yolo11n.xml \
        threshold=0.5 \
        device=$DEVICE \
        $PRE_PROCESS $DETECTION_OPTIONS \
    ! gvametaconvert \
    ! tee name=t \
        t. ! queue $QUEUE_PARAMS ! $OUTPUT \
        t. ! queue $QUEUE_PARAMS ! gvametapublish name=destination file-format=json-lines file-path=/tmp/results/r\$cid.jsonl ! fakesink sync=false async=false \
    2>&1 | tee /tmp/results/gst-launch_\$cid.log \
    | (stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline\$cid.log)"

echo "$gstLaunchCmd"

eval $gstLaunchCmd
