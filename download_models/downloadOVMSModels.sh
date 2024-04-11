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
modelDir="$MODEL_EXEC_PATH/../configs/opencv-ovms/models/2022"
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

# downloadOMZmodel function downloads the open model zoo supported models via omz model downloader
downloadOMZmodel(){
    modelNameFromList=$1
    precision=$2
    cmdPrecision=()
    if [ -n "$precision" ]
    then
        cmdPrecision=(--precisions "$precision")
    fi

    docker run -u "$(id -u)":"$(id -g)" --rm -v "$modelDir":/models openvino/ubuntu20_dev:latest omz_downloader --name "$modelNameFromList" --output_dir /models "${cmdPrecision[@]}"
    exitedCode="$?"
    if [ ! "$exitedCode" -eq 0 ]
    then
        echo "Error download $modelNameFromList model from open model zoo"
        return 1
    fi

    docker run -u "$(id -u)":"$(id -g)" --rm -v "$modelDir":/models:rw openvino/ubuntu20_dev:latest omz_converter --name "$modelNameFromList" --download_dir /models --output_dir /models "${cmdPrecision[@]}"
    exitedCode="$?"
    if [ ! "$exitedCode" -eq 0 ]
    then
        echo "Error convert $modelNameFromList model to IR format from open model zoo"
        return 1
    fi

    (
        # create folder 1 under each precision FP directory to hold the .bin and .xml files
        omzModelDir=""
        if [ -d "$modelDir/intel" ]; then
            omzModelDir="$modelDir/intel"
        elif [ -d "$modelDir/public" ]; then
            omzModelDir="$modelDir/public"
        else
            echo "Error: folder \"$modelDir/intel\" or \"$modelDir/public\" was not created by converter."
            exit 1
        fi

        cd "$omzModelDir" || { echo "Error: could not cd to folder \"$omzModelDir\"." ; exit 1; }

        for eachModel in */ ; do
            echo "$eachModel"
            (
                cd "$eachModel" || { echo "Error cd into $eachModel"; exit 1; }
                for FP_Dir in */ ; do
                    echo "$FP_Dir"
                    mkdir -p "$FP_Dir"1
                    mv "$FP_Dir"*.bin "$FP_Dir"1
                    mv "$FP_Dir"*.xml "$FP_Dir"1
                done
            )
        done

        echo "Moving \"$omzModelDir\" to \"$modelDir\""
        mv "$omzModelDir"/* "$modelDir"/
        rm -r "$omzModelDir"
    )

    exitedCode="$?"
    if [ ! "$exitedCode" -eq 0 ]
    then
        echo "Error copying $modelNameFromList model into folder 1"
        return 1
    fi
}

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

# $1 is the model name
# $2 is the model precision
isModelDownloaded() {
    modelName=$1
    precision=$2
    for m in "$modelDir"/* ; do
        if [ "$(basename "$m")" = "$modelName" ]
        then
            if [ -z "$precision" ]
            then
                # empty precision, but found the modelName, so assume it is downloaded
                echo "downloaded"
                return 0
            else
                for precision_folder in "$modelDir"/"$modelName"/* ; do
                    if [ "$(basename "$precision_folder")" = "$precision" ]
                    then
                        echo "downloaded"
                        return 0
                    fi
                done
            fi
        fi
    done
    echo "not_found"
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

### Run normal downloader via omz model downloader:
configFile="$modelDir"/config_template.json
mapfile -t model_base_path < <(docker run -i --rm -v ./:/app ghcr.io/jqlang/jq -r '.model_config_list.[].config.base_path' < "$configFile")

echo "Looping through models defined in $configFile to download models via omz downloader..."
for eachModelBasePath in "${model_base_path[@]}" ; do
    eachModel=$(echo "$eachModelBasePath" | awk -F/ '{print $(NF-1)}')
    precision=$(echo "$eachModelBasePath" | awk -F/ '{print $NF}')
    echo "$eachModel; $precision"

    if [[ "$precision" != FP* ]]
    then
        eachModel=$precision
        precision=""
    fi
    echo "$eachModel; $precision"

    ret=$(isModelDownloaded "$eachModel" "$precision")
    if [ "$ret" = "not_found" ]
    then
        echo "Attempt to download model $eachModel..."
        (
            cd "$MODEL_EXEC_PATH/../download_models" || { echo "Error cd into download_models folder"; exit 1; }
            downloadOMZmodel "$eachModel" "$precision"
            exitedCode="$?"
            if [ ! "$exitedCode" -eq 0 ]
            then
                echo "$eachModel is not supported in open model zoo, skip..."
            else
                echo "successful downloaded $eachModel!"
            fi
        )
    else
        echo "$eachModel model already exists, skip downloading..."
    fi
done

### Run custom downloader section below:
downloadYolov5sFP16INT8
downloadEfficientnetb0
downloadHorizontalText
downloadTextRecognition
