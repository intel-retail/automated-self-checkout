#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

if grep -qi "gpu" <<< "$OCR_DEVICE"; then
	OCR_PP="pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1"
fi

if [ "$INPUTSRC_TYPE" == "REALSENSE" ]; then
        decode_pp="! videoconvert ! video/x-raw,format=BGR"
	# TODO: update with vaapipostproc when MJPEG codec is supported.
	echo "Not supported until D436 with MJPEG." > /tmp/results/pipeline$cid_count.log
	exit 0
fi

if [ "$RENDER_MODE" == "1" ]; then

        gst-launch-1.0 tcpserversrc host=127.0.0.1 port=5000 ! h264parse ! vaapih264dec ! queue ! videoconvert ! xvimagesink sync=true &

        sleep 5

        gst-launch-1.0 $inputsrc ! vaapidecodebin $decode_pp ! "video/x-raw(memory:VASurface)" ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP16-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 gpu-throughput-streams=4 nireq=4 batch-size=1 ! gvatrack name=tracking tracking-type=zero-term-imageless ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=GPU inference-region=roi-list name=classification pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 reclassify_interval=${OCR_RECLASSIFY_INTERVAL} batch-size=8 nireq=4 gpu-throughput-streams=4 ! gvapython class=ObjectFilter module=/home/pipeline-server/extensions/tracked_object_filter.py kwarg=\"{\\\"reclassify_interval\\\": ${OCR_RECLASSIFY_INTERVAL}}\" name=tracked_object_filter ! gvadetect model-instance-id=ocr nireq=4 gpu-throughput-streams=4 batch-size=8 threshold=.2 model=models/horizontal-text-detection-0002/1/FP16-INT8/horizontal-text-detection-0002.xml model-proc=models/horizontal-text-detection-0002/1/horizontal-text-detection-0002.json name=text_detection device=$OCR_DEVICE inference-region=roi-list pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 ! gvainference model-instance-id=ocr2 nireq=4 gpu-throughput-streams=4 batch-size=128 device=GPU model=models/text-recognition-0012-GPU/1/FP16-INT8/text-recognition-0012-mod.xml model-proc=models/text-recognition-0012-GPU/1/text-recognition-0012.json inference-region=roi-list name=text_recognition ! gvapython class=OCR module=/home/pipeline-server/extensions/OCR_post_processing_0012.py name=ocr_postprocess ! gvapython name=barcode class=BarcodeDetection module=/home/pipeline-server/extensions/barcode_nv12_to_gray.py kwarg=\"{\\\"reclassify_interval\\\": ${BARCODE_RECLASSIFY_INTERVAL}}\" ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! \
        gvawatermark ! vaapih264enc  ! tcpclientsink host=127.0.0.1 port=5000
else
	gst-launch-1.0 $inputsrc ! vaapidecodebin $decode_pp ! "video/x-raw(memory:VASurface)" ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP16-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 gpu-throughput-streams=4 nireq=4 batch-size=1 ! gvatrack name=tracking tracking-type=zero-term-imageless ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json device=GPU inference-region=roi-list name=classification pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 reclassify_interval=${OCR_RECLASSIFY_INTERVAL} batch-size=8 nireq=4 gpu-throughput-streams=4 ! gvapython class=ObjectFilter module=/home/pipeline-server/extensions/tracked_object_filter.py kwarg=\"{\\\"reclassify_interval\\\": ${OCR_RECLASSIFY_INTERVAL}}\" name=tracked_object_filter ! gvadetect model-instance-id=ocr nireq=4 gpu-throughput-streams=4 batch-size=8 threshold=.2 model=models/horizontal-text-detection-0002/1/FP16-INT8/horizontal-text-detection-0002.xml model-proc=models/horizontal-text-detection-0002/1/horizontal-text-detection-0002.json name=text_detection device=$OCR_DEVICE inference-region=roi-list pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 ! gvainference model-instance-id=ocr2 nireq=4 gpu-throughput-streams=4 batch-size=128 device=GPU model=models/text-recognition-0012-GPU/1/FP16-INT8/text-recognition-0012-mod.xml model-proc=models/text-recognition-0012-GPU/1/text-recognition-0012.json inference-region=roi-list name=text_recognition ! gvapython class=OCR module=/home/pipeline-server/extensions/OCR_post_processing_0012.py name=ocr_postprocess ! gvapython name=barcode class=BarcodeDetection module=/home/pipeline-server/extensions/barcode_nv12_to_gray.py kwarg=\"{\\\"reclassify_interval\\\": ${BARCODE_RECLASSIFY_INTERVAL}}\" ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 2>&1 | stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log
fi
