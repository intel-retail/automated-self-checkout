#!/bin/bash
#
# Copyright (C) 2025 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#
set -eo pipefail

# Create results directory
mkdir -p /tmp/results

if [ "$INPUTSRC_TYPE" == "REALSENSE" ]; then
    echo "Not supported until D436 with MJPEG." > /tmp/results/pipeline$cid.log
    exit 2
fi

RTSP_PATH=${RTSP_PATH:="output_$cid"}
OBJECT_DETECTION_DEVICE="${OBJECT_DETECTION_DEVICE:=$DEVICE}"
OBJECT_CLASSIFICATION_DEVICE="${OBJECT_CLASSIFICATION_DEVICE:=$CLASSIFICATION_DEVICE}"
FACE_DETECTION_DEVICE="${FACE_DETECTION_DEVICE:=$DEVICE}"
AGE_CLASSIFICATION_DEVICE="${AGE_CLASSIFICATION_DEVICE:=$CLASSIFICATION_DEVICE}"
PRE_PROCESS="${PRE_PROCESS:=""}"

if [ "$RENDER_MODE" == "1" ]; then
    OUTPUT="gvawatermark ! videoconvert ! fpsdisplaysink video-sink=autovideosink text-overlay=false signal-fps-measurements=true name=obj_fps_sink"
    AGE_OUTPUT="gvawatermark ! videoconvert ! fpsdisplaysink video-sink=autovideosink text-overlay=false signal-fps-measurements=true name=age_fps_sink"
elif [ "$RTSP_OUTPUT" == "1" ]; then
    OUTPUT="gvawatermark ! x264enc ! video/x-h264,profile=baseline ! rtspclientsink location=$RTSP_SERVER/$RTSP_PATH protocols=tcp timeout=0"
    AGE_OUTPUT="gvawatermark ! x264enc ! video/x-h264,profile=baseline ! rtspclientsink location=$RTSP_SERVER/$AGE_RTSP_PATH protocols=tcp timeout=0"
else
    OUTPUT="fpsdisplaysink video-sink=fakesink signal-fps-measurements=true name=obj_fps_sink"
    AGE_OUTPUT="fpsdisplaysink video-sink=fakesink signal-fps-measurements=true name=age_fps_sink"
fi

echo "Running object detection pipeline on $DEVICE with detection batch size = $BATCH_SIZE_DETECT and classification batch size = $BATCH_SIZE_CLASSIFY"
echo "Running age prediction pipeline on $AGE_PREDICTION_VIDEO"

gstLaunchCmd="GST_DEBUG=\"GST_TRACER:7\" GST_TRACERS='latency_tracer(flags=pipeline)' gst-launch-1.0 --verbose \
    $inputsrc_oc1 ! $DECODE \
    ! queue \
    ! gvadetect batch-size=$BATCH_SIZE_DETECT \
        model-instance-id=odmodel \
        name=object_detection \
        model=/home/pipeline-server/models/object_detection/yolo11n/INT8/yolo11n.xml \
        threshold=0.5 \
        inference-interval=3 \
        scale-method=fast \
        device=$OBJECT_DETECTION_DEVICE \
        $PRE_PROCESS $DETECTION_OPTIONS \
    ! queue \
    ! gvatrack \
        name=object_tracking \
        tracking-type=zero-term-imageless \
    ! queue \
    ! gvaclassify batch-size=$BATCH_SIZE_CLASSIFY \
        model-instance-id=classifier \
        labels=/home/pipeline-server/models/object_classification/efficientnet-b0/INT8/imagenet_2012.txt \
        model=/home/pipeline-server/models/object_classification/efficientnet-b0/INT8/efficientnet-b0-int8.xml \
        model-proc=/home/pipeline-server/models/object_classification/efficientnet-b0/INT8/preproc-aspect-ratio.json \
        device=$OBJECT_CLASSIFICATION_DEVICE \
        name=classification \
        inference-region=1 \
        object-class=object \
        reclassify-interval=1 \
    
        $CLASSIFICATION_PRE_PROCESS $CLASSIFICATION_OPTIONS \
    ! gvametaconvert \
    ! tee name=t_obj \
        t_obj. ! queue ! $OUTPUT \
        t_obj. ! queue ! gvametapublish name=obj_destination file-format=json-lines file-path=/tmp/results/rs_obj\$cid.jsonl ! fakesink sync=false async=false \
    \
    $inputsrc_ap1 ! $DECODE \
    ! queue \
    ! gvadetect batch-size=$BATCH_SIZE_DETECT \
        model-instance-id=facemodel \
        name=face_detection \
        model=/home/pipeline-server/models/face_detection/FP16/face-detection-retail-0004.xml \
        model-proc=/home/pipeline-server/models/face_detection/face-detection-retail-0004.json \
        inference-interval=3 \
        scale-method=fast \
        inference-region=full-frame \
        threshold=0.5 \
        device=$FACE_DETECTION_DEVICE \
        $PRE_PROCESS $DETECTION_OPTIONS \
    ! queue \
    ! gvatrack \
        name=face_tracking \
        tracking-type=zero-term-imageless \
    ! queue \
    ! gvaclassify batch-size=$BATCH_SIZE_CLASSIFY \
        model-instance-id=age_classifier \
        model=/home/pipeline-server/models/age_prediction/FP16/age-gender-recognition-retail-0013.xml \
        model-proc=/home/pipeline-server/models/age_prediction/age-gender-recognition-retail-0013.json \
        device=$AGE_CLASSIFICATION_DEVICE \
        name=age_classification \
        inference-region=roi-list \
        object-class=face \
        reclassify-interval=1 \
    ! queue \
    ! gvametaconvert \
    ! tee name=t \
        t. ! queue ! $AGE_OUTPUT \
        t. ! queue ! gvametapublish name=destination file-format=json-lines file-path=/tmp/results/rs_age\$cid.jsonl ! fakesink sync=false async=false \
    2>&1 | tee /tmp/results/gst-launch_\$cid.log \
    | (stdbuf -oL awk '
        BEGIN { 
            obj_fps = 0; age_fps = 0; 
            pipeline_file = \"/tmp/results/pipeline\" ENVIRON[\"cid\"] \".log\"
        }
        /obj_fps_sink.*current:/ { 
            gsub(/.*current: /, \"\"); 
            gsub(/,.*/, \"\"); 
            obj_fps = \$0;
            combined_fps = obj_fps + age_fps;
            print combined_fps > pipeline_file; 
            fflush(pipeline_file);
        }
        /age_fps_sink.*current:/ { 
            gsub(/.*current: /, \"\"); 
            gsub(/,.*/, \"\"); 
            age_fps = \$0;
            combined_fps = obj_fps + age_fps;
            print combined_fps > pipeline_file; 
            fflush(pipeline_file);
        }')"

echo "$gstLaunchCmd"

eval $gstLaunchCmd
