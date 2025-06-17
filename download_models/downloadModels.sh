#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

modelPrecisionFP16INT8="FP16-INT8"
modelPrecisionFP32INT8="FP32-INT8"
modelPrecisionFP32="FP32"
# Default values
MODEL_NAME=${1:-yolo11n}
MODEL_TYPE=${2:-yolo_v11}
REFRESH_MODE=0

shift 2
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

# Debugging output
echo "MODEL_NAME: $MODEL_NAME"
echo "MODEL_TYPE: $MODEL_TYPE"
echo "REFRESH_MODE: $REFRESH_MODE"

MODEL_EXEC_PATH="$(dirname "$(readlink -f "$0")")"
modelDir="$MODEL_EXEC_PATH/../models"
mkdir -p "$modelDir"
cd "$modelDir" || { echo "Failure to cd to $modelDir"; exit 1; }

if [ "$REFRESH_MODE" -eq 1 ]; then
    # cleaned up all downloaded files so it will re-download all files again
    echo "In refresh mode, clean the existing downloaded models if any..."
    (
        cd "$MODEL_EXEC_PATH"/.. || echo "failed to cd to $MODEL_EXEC_PATH/.."
        make clean-models
    )
fi

pipelineZooModel="https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/"

# Function to call the Python script for downloading and converting models
downloadModel() {
    local model_name=$1
    local model_type=$2
    echo "[INFO] Checking if YOLO model already exists: $MODEL_NAME"
    local output_dir="object_detection/$MODEL_NAME"
    local bin_path="$output_dir/FP16/${MODEL_NAME}.bin"
     if [ -f "$bin_path" ]; then
        echo "[INFO] Model $MODEL_NAME already exists at $bin_path. Skipping download and setup."
        return 1
    fi

    VENV_DIR="$HOME/.virtualenvs/dlstreamer"
    if [ ! -d "$VENV_DIR" ]; then
        echo "Creating virtual environment in $VENV_DIR..."
        python3 -m venv "$VENV_DIR" || { echo "Failed to create virtual environment"; exit 1; }
    fi

# Activate the virtual environment
    echo "Activating virtual environment in $VENV_DIR..."
    source "$VENV_DIR/bin/activate"

# Install required Python packages
    echo "Installing required Python packages..."
    pip install --upgrade pip
    pip install -r ../download_models/requirements.txt || { echo "Failed to install Python packages"; exit 1; 	}
    echo "Downloading and converting model: $model_name ($model_type)"
    mkdir -p "$output_dir"
    pwd
  # Call the Python script
    python3 ../download_models/download_convert_model.py "$MODEL_NAME" "$MODEL_TYPE" --output_dir "$output_dir"
    if [ $? -ne 0 ]; then
    echo "Error: Failed to download and convert model $model_name"
    exit 1
    fi

    echo "Model $model_name downloaded and converted successfully!"
}
# $1 model file name
# $2 download URL
# $3 model percision
getModelFiles() {
    # Get the models
    wget "$2"/"$3"/"$1"".bin" -P "$4"/"$1"/"$3"/
    wget "$2"/"$3"/"$1"".xml" -P "$4"/"$1"/"$3"/
}

# $1 model file name
# $2 download URL
# $3 json file name
# $4 process file name (this can be different than the model name ex. horizontal-text-detection-0001 is using horizontal-text-detection-0002.json)
# $5 precision folder
getProcessFile() {
    # Get process file
    wget "$2"/"$3".json -O "$5"/"$1"/"$4".json
}

# $1 model name
# $2 download label URL
# $3 label file name
getLabelFile() {
    wget "$2/$3" -P "$4"/"$1"
}


# efficientnet-b0 (model is unsupported in {'FP32-INT8'} precisions, so we have custom downloading function below:
downloadEfficientnetb0() {
    efficientnetb0="efficientnet-b0"
    modelType=object_classification
    # FP32-INT8 efficientnet-b0 for capi
    customefficientnetb0Modelfile="$modelType/$efficientnetb0/$efficientnetb0.json"
    if [ ! -f $customefficientnetb0Modelfile ]; then
        echo "downloading model efficientnet $modelPrecisionFP32INT8 model..."

        wget "https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/efficientnet-b0_INT8/$modelPrecisionFP32INT8/efficientnet-b0.bin" -P "$modelType/$efficientnetb0/$modelPrecisionFP32"
        wget "https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/efficientnet-b0_INT8/$modelPrecisionFP32INT8/efficientnet-b0.xml" -P "$modelType/$efficientnetb0/$modelPrecisionFP32"
        wget "https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/efficientnet-b0_INT8/efficientnet-b0.json" -P "$modelType/$efficientnetb0"
        wget "https://raw.githubusercontent.com/dlstreamer/dlstreamer/master/samples/labels/imagenet_2012.txt" -P "$modelType/$efficientnetb0"
    else
        echo "efficientnet $modelPrecisionFP32INT8 model already exists, skip downloading..."
    fi
}

downloadHorizontalText() {
    horizontalText0002="horizontal-text-detection-0002"
    modelType="text_detection"
    horizontaljsonfilepath="$modelType/$horizontalText0002/$horizontalText0002.json"

    if [ ! -f $horizontaljsonfilepath ]; then
        getModelFiles $horizontalText0002 $pipelineZooModel$horizontalText0002 $modelPrecisionFP16INT8 $modelType
        getProcessFile $horizontalText0002 $pipelineZooModel$horizontalText0002 $horizontalText0002 $horizontalText0002 $modelType
        mv "$modelType/$horizontalText0002/$modelPrecisionFP16INT8" "$modelType/$horizontalText0002/$modelPrecisionFP32"
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
        mv "$modelType/$textRec0012Mod" "$modelType/$textRec0012"
        mv "$modelType/$textRec0012/$modelPrecisionFP16INT8/$textRec0012Mod.xml" "$modelType/$textRec0012/$modelPrecisionFP16INT8/$textRec0012.xml"
        mv "$modelType/$textRec0012/$modelPrecisionFP16INT8/$textRec0012Mod.bin" "$modelType/$textRec0012/$modelPrecisionFP16INT8/$textRec0012.bin"
        mv "$modelType/$textRec0012/$modelPrecisionFP16INT8" "$modelType/$textRec0012/$modelPrecisionFP32"
        mv "$modelType/$textRec0012/$textRec0012Mod.json" "$modelType/$textRec0012/$textRec0012.json"
    else
        echo "textRec0012 $modelPrecisionFP16INT8 model already exists, skip downloading..."
    fi
}

### Run custom downloader section below:
downloadModel "$MODEL_NAME" "$MODEL_TYPE"
downloadEfficientnetb0
downloadHorizontalText
downloadTextRecognition
