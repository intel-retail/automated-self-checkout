 #!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

DECODE="vaapidecodebin" 
DEVICE="CPU" #GPU|CPU|MULTI:GPU,CPU
PRE_PROCESS="" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 
AGGREGATE="gvametaaggregate name=aggregate !" #""|gvametaaggregate name=aggregate !

while :; do
    case $1 in
    -h | -\? | --help)
        show_help
        exit
        ;;
    --decode)
        if [ "$2" ]; then
            DECODE=$2
            shift
        else
            echo "using default"
            # error 'ERROR: "--decode" requires an argument vaapidecodebin|decodebin.'
        fi
        ;;
    --device)
        if [ "$2" ]; then
            DEVICE=$2
            if [ -z "$LOW_POWER" ]; then
                DEVICE="MULTI:GPU,CPU"
            fi
            shift
        else
            echo "using default"
            # error 'ERROR: "--decode" requires an argument GPU|CPU|MULTI:GPU,CPU.'
        fi
        ;;
    --pre_process) 
        if [ "$2" ]; then
            PRE_PROCESS=$2
            shift
        else
            echo "using default"
            # error 'ERROR: "--decode" requires an argument ""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 .'
        fi
        ;;
    --aggregate)
        if [ "$2" ]; then
            AGGREGATE=$2
            shift
        else
            echo "using default"
            # error 'ERROR: "--decode" requires an argument ""|gvametaaggregate name=aggregate !.'
        fi
        ;;
    --render_mode)  
        RENDER_MODE=1
        ;;
    -?*)
        error "ERROR: Unknown option $1"
        ;;
    ?*)
        error "ERROR: Unknown option $1"
        ;;
    *)
        break
        ;;
    esac
    shift
done

# if [ "$AUTO_SCALE_FLEX_140" == "1" ]
# then
#         deviceid=$(($cid_count % 2))
#         if [ "$deviceid" == "0" ]
#         then
#                 GST_VAAPI_DRM_DEVICE=/dev/dri/renderD128
#         else
#                 GST_VAAPI_DRM_DEVICE=/dev/dri/renderD129
#         fi
# 	export GST_VAAPI_DRM_DEVICE="$GST_VAAPI_DRM_DEVICE"
# fi

if [ "$RENDER_MODE" == "1" ]; then
	gst-launch-1.0 $inputsrc ! $DECODE ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=$DEVICE $PRE_PROCESS ! $AGGREGATE gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl  \
	! videoconvert ! video/x-raw,format=I420 \
	! gvawatermark ! videoconvert ! fpsdisplaysink video-sink=ximagesink sync=true --verbose \
	2>&1 | tee >/tmp/results/gst-launch_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
else
    echo "run pipeline"
    gst-launch-1.0 $inputsrc ! $DECODE ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=$DEVICE $PRE_PROCESS ! $AGGREGATE gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst-launch_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
fi

#  dgpu
# gst-launch-1.0 $inputsrc ! vaapidecodebin ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 ! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst-launch_dgpu$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
# xeon
# gst-launch-1.0 $inputsrc ! decodebin ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=CPU ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst-launch_xeon_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
# core
# gst-launch-1.0 $inputsrc ! vaapidecodebin ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU $pre_process ! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst-launch_core_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
# arc
# gst-launch-1.0 $inputsrc ! vaapidecodebin ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 ! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst-launch_arc_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)