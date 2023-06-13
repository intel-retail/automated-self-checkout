#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

modelPrecisionFP16=FP16
modelPrecisionFP32=FP32
modelPrecisionFP16INT8=FP16-INT8
modelPrecisionFP32INT8=FP32-INT8

MODEL_EXEC_PATH="$(dirname "$(readlink -f "$0")")"
modelDir="$MODEL_EXEC_PATH/../configs/dlstreamer/models/2022/"
pipelineZooModel="https://github.com/dlstreamer/pipeline-zoo-models/raw/main/storage/"
openModelZoo="https://storage.openvinotoolkit.org/repositories/open_model_zoo/2022.1/models_bin/3/"
dlstreamerLabel="https://raw.githubusercontent.com/dlstreamer/dlstreamer/master/samples/labels/"

# $1 model file name
# $2 download URL
# $3 model percision
getModelFiles() {
    # Make model directory
    # ex. kdir efficientnet-b0/1/FP16-INT8
    mkdir -p $1/1/$3
    
    # Get the models
    wget $2/$3/$1".bin" -P $1/1/$3
    wget $2/$3/$1".xml" -P $1/1/$3
}

# $1 model file name
# $2 download URL
# $3 process file name (this can be different than the model name ex. horizontal-text-detection-0001 is using horizontal-text-detection-0002.json)
getProcessFile() {
    # Get process file
    wget $2/$3.json -P $1/1
}

getLabelFile() {
    mkdir -p $1/1

    wget $2/$3 -P $1/1
}

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

efficientNet="efficientnet-b0"
efficientNetDir="efficientnet-b0_INT8"
horizontalText0001="horizontal-text-detection-0001"
horizontalText0002="horizontal-text-detection-0002"
textRecognition0012GPU="text-recognition-0012-GPU"
textRec0014="text-recognition-0014"
yolov5s="yolov5s"

# Move to model working directory
mkdir -p $modelDir
cd $modelDir || { echo "Failure to cd to $modelDir"; exit 1; }

if [ "$REFRESH_MODE" -eq 1 ]; then
    # cleaned up all downloaded files so it will re-download all files again
    rm -rf "${PWD}/${efficientNet:?}/"  || true
    rm -rf "${PWD}/${horizontalText0001:?}/"  || true
    rm -rf "${PWD}/${horizontalText0002:?}/" || true
    rm -rf "${PWD}/${textRecognition0012GPU:?}/" || true
    rm -rf "${PWD}/${textRec0014:?}/" || true
    # we don't delete the whole directory as there are some exisitng checked-in files
    rm "${PWD}/$yolov5s/1/FP16-INT8/yolov5s.bin" || true
    rm "${PWD}/$yolov5s/1/FP16-INT8/yolov5s.xml" || true
    rm "${PWD}/$yolov5s/1/FP16/yolov5s.bin" || true
    rm "${PWD}/$yolov5s/1/FP16/yolov5s.xml" || true
    rm "${PWD}/$yolov5s/1/FP32-INT8/yolov5s.bin" || true
    rm "${PWD}/$yolov5s/1/FP32-INT8/yolov5s.xml" || true
    rm "${PWD}/$yolov5s/1/FP32/yolov5s.bin" || true
    rm "${PWD}/$yolov5s/1/FP32/yolov5s.xml" || true
    rm "${PWD}/$yolov5s/1/yolov5s.json" || true
fi

# EfficientNet
# checking whether the model file .bin already exists or not before downloading
efficientNetModelFile="${PWD}/$efficientNet/1/$modelPrecisionFP16INT8/$efficientNet.bin"
echo $efficientNetModelFile
if [ -f "$efficientNetModelFile" ]; then
    echo "models already exists, skip downloading..."
    exit 0
fi

echo "Downloading models..."

getModelFiles $efficientNet $pipelineZooModel$efficientNetDir $modelPrecisionFP16INT8
getProcessFile $efficientNet $pipelineZooModel$efficientNetDir $efficientNet
getLabelFile $efficientNet $dlstreamerLabel "imagenet_2012.txt"
# EfficientNet get efficientnet.ckpt files
wget "https://storage.openvinotoolkit.org/repositories/open_model_zoo/public/2022.1/efficientnet-b0/efficientnet-b0.tar.gz" -P $efficientNet/1/
tar -xvkf $efficientNet/1/efficientnet-b0.tar.gz -C $efficientNet/1/
rm $efficientNet/1/efficientnet-b0.tar.gz

# Horizontal Text 0001
getModelFiles $horizontalText0001 $openModelZoo$horizontalText0001 $modelPrecisionFP16INT8
getProcessFile $horizontalText0001 $pipelineZooModel$horizontalText0002 $horizontalText0002
mv $horizontalText0001/1/$horizontalText0002.json $horizontalText0001/1/$horizontalText0001.json 

# Horizontal Text 0002
getModelFiles $horizontalText0002 $pipelineZooModel$horizontalText0002 $modelPrecisionFP16INT8
getProcessFile $horizontalText0002 $pipelineZooModel$horizontalText0002 $horizontalText0002
cp Horizontal-text-detection-0002_fix.json ./$horizontalText0002/1/horizontal-text-detection-0002.json

# Text Recognition 12 GPU
textRec0012GPU="text-recognition-0012-mod"
textRec0012="text-recognition-0012"
getModelFiles $textRec0012GPU $pipelineZooModel$textRec0012GPU $modelPrecisionFP16INT8
getProcessFile $textRec0012GPU $pipelineZooModel$textRec0012GPU $textRec0012GPU
mv $textRec0012GPU/1/$textRec0012GPU.json $textRec0012GPU/1/$textRec0012.json
mv $textRec0012GPU/ "$textRecognition0012GPU"

# Text Recognition 14
getModelFiles $textRec0014 $openModelZoo$textRec0014 $modelPrecisionFP16INT8
getProcessFile $textRec0014 $pipelineZooModel$textRec0012GPU $textRec0012GPU
mv $textRec0014/1/$textRec0012GPU.json $textRec0014/1/$textRec0012.json

# Yolov5s
getModelFiles $yolov5s $pipelineZooModel"yolov5s-416" $modelPrecisionFP16
getModelFiles $yolov5s $pipelineZooModel"yolov5s-416" $modelPrecisionFP32
getProcessFile $yolov5s $pipelineZooModel"yolov5s-416" $yolov5s

# Yolov5s INT8
getModelFiles $yolov5s $pipelineZooModel"yolov5s-416_INT8" $modelPrecisionFP16INT8
getModelFiles $yolov5s $pipelineZooModel"yolov5s-416_INT8" $modelPrecisionFP32INT8

# give some time for files settling down
sleep 3
