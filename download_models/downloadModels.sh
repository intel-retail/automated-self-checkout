#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

modelPrecisionFP16INT8="FP16-INT8"
modelPrecisionFP32INT8="FP32-INT8"

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
modelDir="$MODEL_EXEC_PATH/../models"
mkdir -p $modelDir
cd $modelDir || { echo "Failure to cd to $modelDir"; exit 1; }

if [ "$REFRESH_MODE" -eq 1 ]; then
    # cleaned up all downloaded files so it will re-download all files again
    echo "In refresh mode, clean the existing downloaded models if any..."
    (
        cd "$MODEL_EXEC_PATH"/.. || echo "failed to cd to $MODEL_EXEC_PATH/.."
        make clean-models
    )
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
# $3 json file name
# $4 process file name (this can be different than the model name ex. horizontal-text-detection-0001 is using horizontal-text-detection-0002.json)
# $5 precision folder
getProcessFile() {
    # Get process file
    wget "$2"/"$3".json -O "$1"/"$5"/1/"$4".json
}

# $1 model name
# $2 download label URL
# $3 label file name
getLabelFile() {
    mkdir -p "$1/1"

    wget "$2/$3" -P "$1/1"
}

# custom yolov5s model downloading for this particular precision FP16INT8
downloadYolov5sFP16INT8() {
    yolov5s="yolov5s"
    yolojson="yolo-v5"

    # checking whether the model file .bin already exists or not before downloading
    yolov5ModelFile="${PWD}/$yolov5s/$modelPrecisionFP16INT8/1/$yolov5s.bin"
    if [ -f "$yolov5ModelFile" ]; then
        echo "yolov5s $modelPrecisionFP16INT8 model already exists in $yolov5ModelFile, skip downloading..."
    else
        echo "Downloading yolov5s $modelPrecisionFP16INT8 models..."
        # Yolov5s FP16_INT8
        getModelFiles $yolov5s $pipelineZooModel"yolov5s-416_INT8" $modelPrecisionFP16INT8
        getProcessFile $yolov5s $pipelineZooModel"yolov5s-416" $yolojson $yolov5s $modelPrecisionFP16INT8
        echo "yolov5 $modelPrecisionFP16INT8 model downloaded in $yolov5ModelFile"
    fi
}

# efficientnet-b0 (model is unsupported in {'FP32-INT8'} precisions, so we have custom downloading function below:
downloadEfficientnetb0() {
    efficientnetb0="efficientnet-b0"
    # FP32-INT8 efficientnet-b0 for capi
    customefficientnetb0Modelfile="$efficientnetb0/$modelPrecisionFP32INT8/1/efficientnet-b0.xml"
    if [ ! -f $customefficientnetb0Modelfile ]; then
        echo "downloading model efficientnet $modelPrecisionFP32INT8 model..."
        mkdir -p "$efficientnetb0"/"$modelPrecisionFP32INT8"
        mkdir -p "$efficientnetb0"/"$modelPrecisionFP32INT8"/1

        wget "https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/efficientnet-b0_INT8/$modelPrecisionFP32INT8/efficientnet-b0.bin" -P "$efficientnetb0/$modelPrecisionFP32INT8/1"
        wget "https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/efficientnet-b0_INT8/$modelPrecisionFP32INT8/efficientnet-b0.xml" -P "$efficientnetb0/$modelPrecisionFP32INT8/1"

        dlstreamerLabelURL="https://raw.githubusercontent.com/dlstreamer/dlstreamer/master/samples/labels/"
        textEfficiennetJsonFilePath="$efficientnetb0/$efficientnetb0.json"
        if [ ! -f $textEfficiennetJsonFilePath ]; then
            wget "https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/efficientnet-b0_INT8/efficientnet-b0.json" -O "$efficientnetb0/$efficientnetb0.json"
            getLabelFile $efficientnetb0 $dlstreamerLabelURL "imagenet_2012.txt"
        fi
    else
        echo "efficientnet $modelPrecisionFP32INT8 model already exists, skip downloading..."
    fi
}

downloadHorizontalText() {
    horizontalText0002="horizontal-text-detection-0002"
    horizontaljsonfilepath="$horizontalText0002/$modelPrecisionFP16INT8/1/$horizontalText0002.json"
    if [ ! -f $horizontaljsonfilepath ]; then
        getModelFiles $horizontalText0002 $pipelineZooModel$horizontalText0002 $modelPrecisionFP16INT8
        getProcessFile $horizontalText0002 $pipelineZooModel$horizontalText0002 $horizontalText0002 $horizontalText0002 $modelPrecisionFP16INT8
    fi
}

downloadTextRecognition() {
    textRec0012Mod="text-recognition-0012-mod"
    textRec0012Modjsonfilepath="$textRec0012Mod/$modelPrecisionFP16INT8/1/$textRec0012Mod.json"
    if [ ! -f $textRec0012Modjsonfilepath ]; then
        getModelFiles $textRec0012Mod $pipelineZooModel$textRec0012Mod $modelPrecisionFP16INT8
        getProcessFile $textRec0012Mod $pipelineZooModel$textRec0012Mod $textRec0012Mod $textRec0012Mod $modelPrecisionFP16INT8
    fi
}

### Run custom downloader section below:
downloadYolov5sFP16INT8
downloadEfficientnetb0
downloadHorizontalText
downloadTextRecognition
