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
	exit 0
fi

# arc only
# GST_VAAPI_DRM_DEVICE=/dev/dri/renderD129
# export GST_VAAPI_DRM_DEVICE="$GST_VAAPI_DRM_DEVICE"

DEVICE="CPU" #GPU|CPU|MULTI:GPU,CPU
PRE_PROCESS="pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 batch-size=1 nireq=4 gpu-throughput-streams=4" #""|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 batch-size=1 nireq=4 gpu-throughput-streams=4 
PRE_PROCESS2="pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4" #""|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4
GST_LAUNCH_LOG_PREFIX="gst-launch_core_" #gst-launch_core_|gst-launch_arc_|gst-launch_dgpu_|gst-launch_xeon_

if [ "1" == "$LOW_POWER" ]
then
	echo "Enabled GPU based low power pipeline "
	gst-launch-1.0 $inputsrc ! vaapidecodebin ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU $pre_process ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=GPU inference-region=roi-list name=classification $pre_process ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/$GST_LAUNCH_LOG_PREFIX$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
elif [ "$CPU_ONLY" == "1" ] 
then
	echo "Enabled CPU inference pipeline only"
	gst-launch-1.0 $inputsrc ! decodebin force-sw-decoders=1 ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=CPU ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=CPU inference-region=roi-list name=classification ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/$GST_LAUNCH_LOG_PREFIX$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
else
    echo "Enabled $DEVICE pipeline"
	gst-launch-1.0 $inputsrc ! vaapidecodebin $decode_pp ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU $PRE_PROCESS ! gvatrack name=tracking tracking-type=zero-term-imageless ! queue max-size-bytes=0 max-size-buffers=0 max-size-time=0 ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=GPU inference-region=roi-list name=classification $PRE_PROCESS2 ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | tee >/tmp/results/$GST_LAUNCH_LOG_PREFIX$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
fi