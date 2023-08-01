 #!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

DECODE="decodebin" #decodebin|vaapidecodebin
DEVICE="CPU" #GPU|CPU|MULTI:GPU,CPU
PRE_PROCESS="" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 
AGGREGATE="gvametaaggregate name=aggregate !" #""|gvametaaggregate name=aggregate !
outputFormat="! fpsdisplaysink video-sink=fakesink sync=true --verbose"

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
        fi
        ;;
    --pre_process) 
        if [ "$2" ]; then
            PRE_PROCESS=$2
            shift
        else
            echo "using default"
        fi
        ;;
    --aggregate)
        if [ "$2" ]; then
            AGGREGATE=$2
            shift
        else
            echo "using default"
        fi
        ;;
    --render_mode)  
        outputFormat="! videoconvert ! video/x-raw,format=I420 ! gvawatermark ! videoconvert ! fpsdisplaysink video-sink=ximagesink sync=true --verbose"
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

echo "run pipeline"
gst-launch-1.0 $inputsrc ! $DECODE ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=$DEVICE $PRE_PROCESS ! $AGGREGATE gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl $outputFormat 2>&1 | tee >/tmp/results/gst-launch_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)