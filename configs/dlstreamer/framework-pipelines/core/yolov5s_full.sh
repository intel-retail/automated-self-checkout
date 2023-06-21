#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

if grep -qi "gpu" <<< "$OCR_DEVICE"; then
	OCR_PP="pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1"

fi

echo "INPUTSRC_TYPE: $INPUTSRC_TYPE"

if [ "$INPUTSRC_TYPE" == "REALSENSE" ]; then
        decode_pp="! videoconvert ! video/x-raw,format=BGR"
	# TODO: update with vaapipostproc when MJPEG codec is supported.
        echo "Not supported until D436 with MJPEG." > /tmp/results/pipeline$cid_count.log
        exit 0
fi

gst-launch-1.0 $inputsrc ! vaapidecodebin $decode_pp ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP32-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 ! gvatrack name=tracking tracking-type=zero-term-imageless ! tee name=branch ! queue ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json reclassify-interval=1 device=GPU inference-region=roi-list name=classification pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 ! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose branch. ! queue ! gvapython class=ObjectFilter module=/home/pipeline-server/extensions/tracked_object_filter.py kwarg=\"{\\\"reclassify_interval\\\": ${OCR_RECLASSIFY_INTERVAL}}\" name=tracked_object_filter ! gvadetect model-instance-id=ocr threshold=.40 model=models/horizontal-text-detection-0001/1/FP16-INT8/horizontal-text-detection-0001.xml model-proc=models/horizontal-text-detection-0001/1/horizontal-text-detection-0001.json name=text_detection device=$OCR_DEVICE inference-region=roi-list $OCR_PP ! gvainference model-instance-id=ocr2 device=$OCR_DEVICE model=models/text-recognition-0014/1/FP16-INT8/text-recognition-0014.xml model-proc=models/text-recognition-0014/1/text-recognition-0012.json inference-region=roi-list name=text_recognition object-class=text ! gvapython class=OCR module=/home/pipeline-server/extensions/OCR_post_processing.py name=ocr_postprocess ! aggregate. branch. ! queue ! gvapython name=barcode class=BarcodeDetection module=/home/pipeline-server/extensions/barcode_nv12_to_gray.py  kwarg=\"{\\\"reclassify_interval\\\": ${BARCODE_RECLASSIFY_INTERVAL}}\" ! aggregate. 2>&1 | tee >/tmp/results/gst-launch_core_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
