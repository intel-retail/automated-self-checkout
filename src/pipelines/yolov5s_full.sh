 #!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE="${DEVICE:="GPU"}" #GPU|CPU|MULTI:GPU,CPU
PRE_PROCESS="${PRE_PROCESS:=""}" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 
DETECTION_OPTIONS="${DETECTION_OPTIONS:=""}" # Extra detection model parameters ex. "" | gpu-throughput-streams=4 nireq=4 batch-size=1
CLASSIFICATION_OPTIONS="${CLASSIFICATION_OPTIONS:="reclassify-interval=1 $DETECTION_OPTIONS"}" # Extra Classification model parameters ex. "" | reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4
VA_SURFACE="${VA_SURFACE:=""}" # VA surface to use for shared memory ex. ""|! "video/x-raw(memory:VASurface)" (GPU only)
PARALLEL_PIPELINE="${PARALLEL_PIPELINE:=""}" # Run pipeline in parallel using the tee branch ex. ""|! tee name=branch ! queue
PARALLEL_AGGRAGATE="${PARALLEL_AGGRAGATE:=""}" # Aggregate parallel pipeline results together ex. "" | ! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose branch. ! queue !
OCR_RECLASSIFY_INTERVAL="${OCR_RECLASSIFY_INTERVAL:=5}"
BARCODE_RECLASSIFY_INTERVAL="${BARCODE_RECLASSIFY_INTERVAL:=5}"

if [ "$RENDER_MODE" == "1" ]; then
    OUTPUT="${OUTPUT:="! videoconvert ! video/x-raw,format=I420 ! gvawatermark ! videoconvert ! fpsdisplaysink video-sink=ximagesink sync=true --verbose"}"
else
    OUTPUT="${OUTPUT:="! fpsdisplaysink video-sink=fakesink sync=true --verbose"}"
fi

# generate unique container id based on the date with the precision upto nano-seconds
cid=$(date +%Y%m%d%H%M%S%N)
echo "cid: $cid"

gstLaunchCmd="gst-launch-1.0 $inputsrc ! decodebin  ! gvadetect model-instance-id=odmodel name=detection model=/home/pipeline-server/models/yolov5s/FP16-INT8/1/yolov5s.xml model-proc=/home/pipeline-server/models/yolov5s/FP16-INT8/1/yolov5s.json threshold=.5 device=$DEVICE ! gvatrack name=tracking tracking-type=zero-term-imageless ! gvaclassify model-instance-id=clasifier labels=/home/pipeline-server/models/efficientnet-b0/1/imagenet_2012.txt model=/home/pipeline-server/models/efficientnet-b0/FP32-INT8/1/efficientnet-b0.xml model-proc=/home/pipeline-server/models/efficientnet-b0/efficientnet-b0.json reclassify-interval=1 device=$DEVICE inference-region=roi-list name=classification ! gvapython class=ObjectFilter module=/home/pipeline-server/extensions/tracked_object_filter.py kwarg=\"{\\\"reclassify_interval\\\": $BARCODE_RECLASSIFY_INTERVAL}\" name=tracked_object_filter ! gvadetect model-instance-id=ocr threshold=.40 model=/home/pipeline-server/models/horizontal-text-detection-0002/FP16-INT8/1/horizontal-text-detection-0002.xml model-proc=/home/pipeline-server/models/horizontal-text-detection-0002/FP16-INT8/1/horizontal-text-detection-0002.json name=text_detection device=CPU inference-region=roi-list ! gvainference model-instance-id=ocr2 device=CPU model=/home/pipeline-server/models/text-recognition-0012-mod/FP16-INT8/1/text-recognition-0012-mod.xml model-proc=/home/pipeline-server/models/text-recognition-0012-mod/FP16-INT8/1/text-recognition-0012-mod.json inference-region=roi-list name=text_recognition object-class=text ! gvapython class=OCR module=/home/pipeline-server/extensions/OCR_post_processing_0012.py name=ocr_postprocess ! gvapython name=barcode class=BarcodeDetection module=/home/pipeline-server/extensions/barcode_nv12_to_gray.py  kwarg=\"{\\\"reclassify_interval\\\": $BARCODE_RECLASSIFY_INTERVAL}\" ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid.jsonl $OUTPUT 2>&1 | tee >/tmp/results/gst-launch_$cid.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid.log)"

echo "$gstLaunchCmd"

eval $gstLaunchCmd

# while true; do echo hi; sleep 30; done