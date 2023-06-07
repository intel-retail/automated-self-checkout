#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

if [ "$INPUTSRC_TYPE" == "REALSENSE" ]; then
        decode_pp="! videoconvert ! video/x-raw,format=BGR"
	# TODO: update with vaapipostproc when MJPEG codec is supported.
        echo "Not supported until D436 with MJPEG." > /tmp/results/pipeline$cid_count.log
        exit 0
fi


if [ "1" == "$LOW_POWER" ]
then
	echo "Enabled GPU based low power pipeline "
	gst-launch-1.0 $inputsrc ! vaapidecodebin ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU $pre_process ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=GPU inference-region=roi-list name=classification $pre_process ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst-launch_core_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)

elif [ "$CPU_ONLY" == "1" ] 
then
	echo "Enabled CPU inference pipeline only"
	gst-launch-1.0 $inputsrc ! decodebin force-sw-decoders=1 ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=CPU ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=CPU inference-region=roi-list name=classification ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst-launch_core_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)

else
	echo "Enabled CPU+iGPU pipeline"
	gst-launch-1.0 $inputsrc ! vaapidecodebin ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=MULTI:GPU,CPU ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=MULTI:GPU,CPU inference-region=roi-list name=classification ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/gst-launch_core_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)

fi
