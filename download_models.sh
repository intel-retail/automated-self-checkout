#!/bin/bash
#todo: rename this script to something meaningful for the OVMS workload
#todo: update for how we get the bit model
#todo: update to check for models first and skip download if they exist

segmentationModelFile="${PWD}/configs/opencv-ovms/models/2022/instance_segmentation_omz_1040/FP16-INT8/1/instance-segmentation-security-1040.bin"
echo $segmentationModelFile
if [ -f "$segmentationModelFile" ]; then
    echo "models already exists, skip downloading..."
    exit 0
fi
mkdir -p configs/opencv-ovms/models/2022/instance_segmentation_omz_1040/FP16-INT8/1
mkdir -p configs/opencv-ovms/models/2022/BiT_M_R50x1_10C_50e_IR/FP16-INT8/1


cd configs/opencv-ovms/models/2022/instance_segmentation_omz_1040/FP16-INT8/1
wget https://storage.openvinotoolkit.org/repositories/open_model_zoo/2022.3/models_bin/1/instance-segmentation-security-1040/FP16-INT8/instance-segmentation-security-1040.bin
wget https://storage.openvinotoolkit.org/repositories/open_model_zoo/2022.3/models_bin/1/instance-segmentation-security-1040/FP16-INT8/instance-segmentation-security-1040.xml
cd -

