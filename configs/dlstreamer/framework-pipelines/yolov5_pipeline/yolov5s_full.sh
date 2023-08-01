 #!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

DECODE="decodebin" #decodebin|vaapidecodebin
DEVICE="GPU" #GPU|CPU|MULTI:GPU,CPU
PRE_PROCESS="" #""|pre-process-backend=vaapi-surface-sharing|pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 
# arc + gpu-throughput-streams=4 nireq=4 batch-size=1 | dgpu + gpu-throughput-streams=1 nireq=8 batch-size=2
AGGREGATE="" #""|gvametaaggregate name=aggregate | aggregate. branch. ! queue
outputFormat="! fpsdisplaysink video-sink=fakesink sync=true --verbose"
VA_SURFACE="" #""|! "video/x-raw(memory:VASurface)" (GPU only)
PARALLEL_PIPELINE="" #""|! tee name=branch ! queue
PARALLEL_AGGRAGATE="" #""|! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose branch. ! queue !
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
gst-launch-1.0 $inputsrc ! $DECODE $VA_SURFACE ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP16-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=$DEVICE $PRE_PROCESS  gpu-throughput-streams=4 nireq=4 batch-size=1 ! gvatrack name=tracking tracking-type=zero-term-imageless $PARALLEL_PIPELINE ! gvaclassify model-instance-id=clasifier labels=models/efficientnet-b0/1/imagenet_2012.txt model=models/efficientnet-b0/1/FP16-INT8/efficientnet-b0.xml model-proc=models/efficientnet-b0/1/efficientnet-b0.json reclassify-interval=1  device=$DEVICE inference-region=roi-list name=classification $PRE_PROCESS reclassify_interval=${OCR_RECLASSIFY_INTERVAL} batch-size=8 nireq=4 gpu-throughput-streams=1 $PARALLEL_AGGRAGATE ! gvapython class=ObjectFilter module=/home/pipeline-server/extensions/tracked_object_filter.py kwarg=\"{\\\"reclassify_interval\\\": ${OCR_RECLASSIFY_INTERVAL}}\" name=tracked_object_filter ! gvadetect model-instance-id=ocr nireq=4 gpu-throughput-streams=4 batch-size=8 threshold=.2 model=models/horizontal-text-detection-0002/1/FP16-INT8/horizontal-text-detection-0002.xml model-proc=models/horizontal-text-detection-0002/1/horizontal-text-detection-0002.json name=text_detection device=$DEVICE inference-region=roi-list $PRE_PROCESS ! gvainference model-instance-id=ocr2 nireq=4 gpu-throughput-streams=2 batch-size=32 device=$DEVICE model=models/text-recognition-0012-GPU/1/FP16-INT8/text-recognition-0012-mod.xml model-proc=models/text-recognition-0012-GPU/1/text-recognition-0012.json inference-region=roi-list name=text_recognition object-class=text ! gvapython class=OCR module=/home/pipeline-server/extensions/OCR_post_processing_0012.py name=ocr_postprocess $AGGREGATE ! gvapython name=barcode class=BarcodeDetection module=/home/pipeline-server/extensions/barcode_nv12_to_gray.py kwarg=\"{\\\"reclassify_interval\\\": ${BARCODE_RECLASSIFY_INTERVAL}}\" !  gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl $outputFormat 2>&1 | tee >/tmp/results/gst-launch_$cid_count.log >(stdbuf -oL sed -n -e 's/^.*current: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
