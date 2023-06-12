#!/bin/bash
#todo: update for how we get the bit model

pipelineZooModel="https://storage.openvinotoolkit.org/repositories/open_model_zoo/2022.3/models_bin/1/"
segmentation="instance-segmentation-security-1040"
modelPrecisionFP16INT8=FP16-INT8
localModelFolderName="instance_segmentation_omz_1040"

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

modelDir="../configs/opencv-ovms/models/2022/"
mkdir -p $modelDir
cd $modelDir || { echo "Failure to cd to $modelDir"; exit 1; }

if [ "$REFRESH_MODE" -eq 1 ]; then
    # cleaned up all downloaded files so it will re-download all files again
    rm "${PWD}/$localModelFolderName/$modelPrecisionFP16INT8/1/$segmentation.bin" || true
    rm "${PWD}/$localModelFolderName/$modelPrecisionFP16INT8/1/$segmentation.xml" || true
    rm -rf $localModelFolderName  || true
    rm -rf BiT_M_R50x1_10C_50e_IR  || true
fi

segmentationModelFile="$localModelFolderName/$modelPrecisionFP16INT8/1/$segmentation.bin"
echo $segmentationModelFile
if [ -f "$segmentationModelFile" ]; then
    echo "models already exists, skip downloading..."
    exit 0
fi

mkdir -p "BiT_M_R50x1_10C_50e_IR/FP16-INT8/1"
mkdir -p "$localModelFolderName/FP16-INT8/1"

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

getOVMSModelFiles $segmentation $pipelineZooModel$segmentation $modelPrecisionFP16INT8 $localModelFolderName