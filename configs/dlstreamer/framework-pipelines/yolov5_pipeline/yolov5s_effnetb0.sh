#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

if [ "$INPUTSRC_TYPE" == "REALSENSE" ]; then
        decode_pp="! videoconvert ! video/x-raw,format=BGR"
	# TODO: update with vaapipostproc when MJPEG codec is supported.
	echo "Not supported until D436 with MJPEG." > /tmp/results/pipeline$cid_count.log
	exit 2
fi

DECODE="vaapidecodebin"
DEVICE="CPU" #GPU|CPU|MULTI:GPU,CPU
PRE_PROCESS="" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1

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
            # error 'ERROR: "--device" requires an argument GPU|CPU|MULTI:GPU,CPU.'
        fi
        ;;
    --pre_process)
        if [ "$2" ]; then
            PRE_PROCESS=$2
            shift
        else
            echo "using default"
            # error 'ERROR: "--pre_process" requires an argument ""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 .'
        fi
        ;;
    --low_power)
        LOW_POWER=1
        ;;
	--cpu_only)
		CPU_ONLY=1
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

if [ "1" == "$LOW_POWER" ]
then
	echo "Enabled GPU based low power pipeline "
	gst-launch-1.0 $inputsrc ! $DECODE ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU $pre_process ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=GPU inference-region=roi-list name=classification $pre_process ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst_launch$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
elif [ "$CPU_ONLY" == "1" ] 
then
	echo "Enabled CPU inference pipeline only"
	gst-launch-1.0 $inputsrc ! $DECODE force-sw-decoders=1 ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=CPU ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=CPU inference-region=roi-list name=classification ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst_launch$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
else
    echo "Enabled $DEVICE pipeline"
	gst-launch-1.0 $inputsrc ! $DECODE $decode_pp ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU $pre_process gpu-throughput-streams=4 nireq=4 batch-size=1 ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=GPU inference-region=roi-list name=classification $pre_process reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4 ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst_launch$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
fi