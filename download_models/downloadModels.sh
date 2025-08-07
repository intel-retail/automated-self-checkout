#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#


# Source the export_yolo_model function from /workspace/downloadAndQuantizeModel.sh
source /workspace/downloadAndQuantizeModel.sh

modelPrecisionFP16INT8="FP16-INT8"
modelPrecisionFP32INT8="FP32-INT8"
modelPrecisionFP32="FP32"
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

MODEL_NAME="yolo11n"
MODEL_TYPE="yolo_v11"

# Debugging output
echo "MODEL_NAME: $MODEL_NAME"
echo "MODEL_TYPE: $MODEL_TYPE"
echo "REFRESH_MODE: $REFRESH_MODE"

MODEL_EXEC_PATH="$(dirname "$(readlink -f "$0")")"
# Allow override of modelDir via environment variable (for container flexibility)
modelDir="${MODELS_DIR:-$(dirname "$MODEL_EXEC_PATH")/models}"
mkdir -p "$modelDir"
cd "$modelDir" || { echo "Failure to cd to $modelDir"; exit 1; }

# Print the actual modelDir for debugging
echo "[DEBUG] Downloading models to: $modelDir"

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
    # Get the models
    echo "[DEBUG] wget .bin to: $modelDir/$4/$1/$3/"
    wget $2/$3/$1.bin -P $modelDir/$4/$1/$3/
    echo "[DEBUG] wget .xml to: $modelDir/$4/$1/$3/"
    wget $2/$3/$1.xml -P $modelDir/$4/$1/$3/
}

# $1 model file name
# $2 download URL
# $3 json file name
# $4 process file name (this can be different than the model name ex. horizontal-text-detection-0001 is using horizontal-text-detection-0002.json)
# $5 precision folder
getProcessFile() {
    # Get process file
    echo "[DEBUG] wget .json to: $modelDir/$5/$1/$4.json"
    wget $2/$3.json -O $modelDir/$5/$1/$4.json
}

# $1 model name
# $2 download label URL
# $3 label file name
getLabelFile() {
    echo "[DEBUG] wget label to: $modelDir/$4/$1"
    wget $2/$3 -P $modelDir/$4/$1
}



downloadHorizontalText() {
    horizontalText0002="horizontal-text-detection-0002"
    modelType="text_detection"
    horizontaljsonfilepath="$modelType/$horizontalText0002/$horizontalText0002.json"
    if [ ! -f $horizontaljsonfilepath ]; then
        getModelFiles $horizontalText0002 $pipelineZooModel$horizontalText0002 $modelPrecisionFP16INT8 $modelType
        getProcessFile $horizontalText0002 $pipelineZooModel$horizontalText0002 $horizontalText0002 $horizontalText0002 $modelType
        mv $modelType/$horizontalText0002/$modelPrecisionFP16INT8 $modelType/$horizontalText0002/$modelPrecisionFP32
    else
        echo "horizontalText0002 $modelPrecisionFP16INT8 model already exists, skip downloading..."
    fi
}

downloadTextRecognition() {
    textRec0012Mod="text-recognition-0012-mod"
    textRec0012="text-recognition-0012"
    modelType="text_recognition"
    textRec0012Modjsonfilepath="$modelType/$textRec0012/$textRec0012.json"
    if [ ! -f $textRec0012Modjsonfilepath ]; then
        getModelFiles $textRec0012Mod $pipelineZooModel$textRec0012Mod $modelPrecisionFP16INT8 $modelType
        getProcessFile $textRec0012Mod $pipelineZooModel$textRec0012Mod $textRec0012Mod $textRec0012Mod $modelType
        mv $modelType/$textRec0012Mod $modelType/$textRec0012
        mv $modelType/$textRec0012/$modelPrecisionFP16INT8/$textRec0012Mod.xml $modelType/$textRec0012/$modelPrecisionFP16INT8/$textRec0012.xml
        mv $modelType/$textRec0012/$modelPrecisionFP16INT8/$textRec0012Mod.bin $modelType/$textRec0012/$modelPrecisionFP16INT8/$textRec0012.bin
        mv $modelType/$textRec0012/$modelPrecisionFP16INT8 $modelType/$textRec0012/$modelPrecisionFP32
        mv $modelType/$textRec0012/$textRec0012Mod.json $modelType/$textRec0012/$textRec0012.json
    else
        echo "textRec0012 $modelPrecisionFP16INT8 model already exists, skip downloading..."
    fi
}

### Run custom downloader section below:
# Call export_yolo_model after Python conversion (if needed)
export_yolo_model
downloadHorizontalText
downloadTextRecognition


echo "###################### Model downloading has been completed successfully #########################"
