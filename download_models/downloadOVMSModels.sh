#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#
# Todo: update document for how we get the bit model
# Here is detail about getting bit model: https://medium.com/openvino-toolkit/accelerate-big-transfer-bit-model-inference-with-intel-openvino-faaefaee8aec

pipelineZooModel="https://storage.openvinotoolkit.org/repositories/open_model_zoo/2022.3/models_bin/1/"
segmentation="instance-segmentation-security-1040"
personVehicleDetection="person-vehicle-bike-detection-2000"
modelPrecisionFP16INT8=FP16-INT8
localSegmentationMdlDirName="instance_segmentation_omz_1040"

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
mkdir -p $modelDir
cd $modelDir || { echo "Failure to cd to $modelDir"; exit 1; }

if [ "$REFRESH_MODE" -eq 1 ]; then
    # cleaned up all downloaded files so it will re-download all files again
    rm -rf $personVehicleDetection  || true 
    rm -rf $localSegmentationMdlDirName  || true    
    rm -rf BiT_M_R50x1_10C_50e_IR  || true
    # we don't delete the whole directory as there are some exisitng checked-in files
    rm "${PWD}/$yolov5s/FP16-INT8/1/yolov5s.bin" || true
    rm "${PWD}/$yolov5s/FP16-INT8/1/yolov5s.xml" || true
    rm "${PWD}/$yolov5s/FP16-INT8/1/yolov5s.json" || true
fi

segmentationModelFile="$localSegmentationMdlDirName/$modelPrecisionFP16INT8/1/$segmentation.bin"
personVehicleDetectionFile="$personVehicleDetection/$modelPrecisionFP16INT8/1/$personVehicleDetection.bin"
echo $segmentationModelFile
segmentationModelDownloaded=0
if [ -f "$segmentationModelFile" ]; then
    echo "segmentation model already exists, skip downloading..."
    segmentationModelDownloaded=1
fi

echo $personVehicleDetectionFile
personVehicleModelDownloaded=0
if [ -f "$personVehicleDetectionFile" ]; then
    echo "People Vehicle model already exists, skip downloading..."
    personVehicleModelDownloaded=1
fi

# $1 model file name
# $2 download URL
# $3 model percision
# $4 local model folder name
getOVMSModelFiles() {
    # Make model directory
    mkdir -p $4/$3/1
    
    # Get the models
    wget $2/$3/$1".bin" -P $4/$3/1
    wget $2/$3/$1".xml" -P $4/$3/1
}

if [ $segmentationModelDownloaded -eq 0 ]; then
    echo "download segmentation model..."
    mkdir -p "$localSegmentationMdlDirName/FP16-INT8/1"
    getOVMSModelFiles $segmentation $pipelineZooModel$segmentation $modelPrecisionFP16INT8 $localSegmentationMdlDirName
fi

if [ $personVehicleModelDownloaded -eq 0 ]; then
    echo "download people vehicle model..."
    mkdir -p "$personVehicleDetection/FP16-INT8/1"
    getOVMSModelFiles $personVehicleDetection $pipelineZooModel$personVehicleDetection $modelPrecisionFP16INT8 $personVehicleDetection
fi

bitModelDirName="BiT_M_R50x1_10C_50e_IR"
bitModelFile="$bitModelDirName/$modelPrecisionFP16INT8/1/bit_64.bin"
echo $bitModelFile
if [ -f "$bitModelFile" ]; then
    echo "BIT model already exists, skip downloading..."
else
    echo "download BIT model..."
    mkdir -p "/FP16-INT8/1"
    BIT_MODEL_DOWNLOADER=$(docker images --format "{{.Repository}}" | grep "bit_model_downloader")
    if [ -z "$BIT_MODEL_DOWNLOADER" ]
    then
        docker build -f "$MODEL_EXEC_PATH"/../Dockerfile.bitModel -t bit_model_downloader:dev "$MODEL_EXEC_PATH"/../
    fi
    docker run -it --rm -v "$modelDir/$bitModelDirName/$modelPrecisionFP16INT8"/1:/result bit_model_downloader:dev
fi


pipelineZooModel="https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/"

# $1 model file name
# $2 download URL
# $3 model percision
getModelFiles() {
    # Make model directory
    # ex. kdir efficientnet-b0/1/FP16-INT8
    mkdir -p "$1"/"$3"/1
    
    # Get the models
    wget "$2"/"$3"/"$1"".bin" -P "$1"/"$3"/1
    wget "$2"/"$3"/"$1"".xml" -P "$1"/"$3"/1
}

# $1 model file name
# $2 download URL
# $3 process file name (this can be different than the model name ex. horizontal-text-detection-0001 is using horizontal-text-detection-0002.json)
getProcessFile() {
    # Get process file
    wget "$2"/"$3".json -P "$1"/"$modelPrecisionFP16INT8"/1
}

yolov5s="yolov5s"

# Yolov5
# checking whether the model file .bin already exists or not before downloading
yolov5ModelFile="${PWD}/$yolov5s/$modelPrecisionFP16INT8/1/$yolov5s.bin"
echo "$yolov5ModelFile"
if [ -f "$yolov5ModelFile" ]; then
    echo "yolov5s model already exists, skip downloading..."
else
    echo "Downloading yolov5s models..."
    # Yolov5s INT8
    getModelFiles $yolov5s $pipelineZooModel"yolov5s-416_INT8" $modelPrecisionFP16INT8
    getProcessFile $yolov5s $pipelineZooModel"yolov5s-416" $yolov5s
fi
