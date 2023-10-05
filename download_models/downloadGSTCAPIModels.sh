#!/bin/bash

# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#
# Todo: update document for how we get the bit model
# Here is detail about getting bit model: https://medium.com/openvino-toolkit/accelerate-big-transfer-bit-model-inference-with-intel-openvino-faaefaee8aec

REFRESH_MODE=0
while [ $# -gt 0 ]; do
    case "$1" in
        --refresh)
            echo "running model downloader in refresh mode"
            REFRESH_MODE=1
            ;;
        *)
            echo "Invalid flag: $1" >&2
            exit 1
            ;;
    esac
    shift
done

MODEL_EXEC_PATH="$(dirname "$(readlink -f "$0")")"
modelDir="$MODEL_EXEC_PATH/../configs/opencv-ovms/models/2022"
mkdir -p "$modelDir"
cd "$modelDir" || { echo "Failure to cd to $modelDir"; exit 1; }

if [ "$REFRESH_MODE" -eq 1 ]; then
    # cleaned up all downloaded files so it will re-download all files again
    rm yolov5s/1/*.xml || true; rm yolov5s/1/*.bin || true
    rm efficientnetb0/1/*.xml  || true; rm efficientnetb0/1/*.bin || true
    rm person-detection-retail-0013/1/*.xml  || true; rm  person-detection-retail-0013/1/*.bin  || true
    rm text-detect-0002/1/*.xml || true; rm text-detect-0002/1/*.bin || true;
    rm face-detect-retail-0005/1/*.xml || true; rm face-detect-retail-0005/1/*.bin || true; 
    rm face-landmarks-0002/1/*.xml || true; rm face-landmarks-0002/1/*.bin || true
    rm face-reid-retail-0095/1/*.xml || true; rm face-reid-retail-0095/1/*.bin || true
fi

# $1 model file name
# $2 download URL
# $3 model percision
# $4 local model folder name
getOVMSModelFiles() {
    # Make model directory
    mkdir -p "$2"
    mkdir -p "$2"/1
    
    # Get the models
    wget "$1.bin" -P "$2"/1
    wget "$1.xml" -P "$2"/1
}


if [ ! -f "yolov5s/1/yolov5s.xml" ]; then
    getOVMSModelFiles https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/yolov5s-416_INT8/FP16-INT8/yolov5s yolov5s
fi

if [ ! -f "efficientnetb0/1/efficientnet-b0.xml" ]; then
    getOVMSModelFiles https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/efficientnet-b0_INT8/FP32-INT8/efficientnet-b0 efficientnetb0
fi

if [ ! -f "person-detection-retail-0013/1/person-detection-retail-0013.xml" ]; then
    getOVMSModelFiles https://storage.openvinotoolkit.org/repositories/open_model_zoo/2023.0/models_bin/1/person-detection-retail-0013/FP16-INT8/person-detection-retail-0013 person-detection-retail-0013
fi

if [ ! -f "text-detect-0002/1/horizontal-text-detection-0002.xml" ]; then
    getOVMSModelFiles https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/horizontal-text-detection-0002/FP16-INT8/horizontal-text-detection-0002 text-detect-0002
fi

if [ ! -f "face-detect-retail-0005/1/face-detection-retail-0005.xml" ]; then
    getOVMSModelFiles https://storage.openvinotoolkit.org/repositories/open_model_zoo/2023.0/models_bin/1/face-detection-retail-0005/FP16-INT8/face-detection-retail-0005 face-detect-retail-0005
fi

if [ ! -f "face-landmarks-0002/1/facial-landmarks-35-adas-0002.xml" ]; then
    getOVMSModelFiles https://storage.openvinotoolkit.org/repositories/open_model_zoo/2023.0/models_bin/1/facial-landmarks-35-adas-0002/FP16-INT8/facial-landmarks-35-adas-0002 face-landmarks-0002
fi

if [ ! -f "face-reid-retail-0095/1/face-reidentification-retail-0095.xml" ]; then
    getOVMSModelFiles https://storage.openvinotoolkit.org/repositories/open_model_zoo/2023.0/models_bin/1/face-reidentification-retail-0095/FP16-INT8/face-reidentification-retail-0095 face-reid-retail-0095
fi