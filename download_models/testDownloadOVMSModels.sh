#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

testModelDownload() {
    if [ -d "$1" ]; then
      # Take action if $DIR exists. #
      # check if there is a 2nd parameter input as the filename
      if [ ! -z "$2" ]; then
        filePath="$1"/"$2"
        if [ -f "$filePath" ]; then
          echo "Passed: found file $filePath"
        else
          echo "Failed: expected file not found $filePath"
          exit 1
        fi
      else
        echo "Passed: found folder $1"
      fi
    else
      echo "Failed: expected folder not found $1"
      exit 1
    fi
}

cleanupOVMSDownload() {
  echo 
  echo "cleaning up opencv-ovms download files..."
  # cleaned up all downloaded files so it will re-download all files again
  rm "../configs/opencv-ovms/models/2022/$localModelFolderName/$modelPrecisionFP16INT8/1/$segmentation.bin" || true
  rm "../configs/opencv-ovms/models/2022/$localModelFolderName/$modelPrecisionFP16INT8/1/$segmentation.xml" || true
  rm -rf "../configs/opencv-ovms/models/2022/$localModelFolderName" || true
  rm -rf "../configs/opencv-ovms/models/2022/BiT_M_R50x1_10C_50e_IR" || true

  echo "done clean up OVMS download."
}

echo
echo "CASE Test 1: happy path"
#download ovms models downloaded
./downloadOVMSModels.sh

modelOVMSDir="../configs/opencv-ovms/models/2022/"
localModelFolderName="instance-segmentation-security-1040"
modelPrecisionFP16INT8=FP16-INT8
segmentation="instance-segmentation-security-1040"

# Test Segmentation download
expectedSegmentationDir=$modelOVMSDir$localModelFolderName
echo "$expectedSegmentationDir"
# Test instance-segmentation-security-1040.bin model file exists
testModelDownload "$expectedSegmentationDir/$modelPrecisionFP16INT8/1" "$segmentation.xml"
expectedSegmentationModelFile="$expectedSegmentationDir/$modelPrecisionFP16INT8/1/$segmentation.xml"
if [ -f "$expectedSegmentationModelFile" ]; then
  echo "Passed: found ${expectedSegmentationModelFile}"
else
  echo "Failed: expect model file not found ${expectedSegmentationModelFile}"
  exit 1
fi

timestamp_ovms_model=$(stat -c %Z "$expectedSegmentationModelFile")

echo 
echo "CASE Test 2: re-run downloadOVMSModels and it should not re-download without --refresh option"
./downloadOVMSModels.sh
timestamp_model_rerun=$(stat -c %Z "$expectedSegmentationModelFile")
if [ "$timestamp_model_rerun" -eq "$timestamp_ovms_model" ]; then
  echo "Passed: re-run downloadOVMSModels and it didn't re-download files"
else
  echo "Failed: re-run downloadOVMSModels and it re-download files"
  cleanupOVMSDownload
  exit 1
fi

echo
echo "CASE Test 3: --refresh option"
# use refresh option to re-test:
./downloadOVMSModels.sh --refresh
if [ -f "$expectedSegmentationModelFile" ]; then
  refresh_timestamp_ovms_model=$(stat -c %Z "$expectedSegmentationModelFile")
  if [ "$refresh_timestamp_ovms_model" -gt "$timestamp_ovms_model" ]; then
    echo "Passed: --refresh option test found ${expectedSegmentationModelFile} and timestamp refreshed"
  else
    echo "Failed: --refresh option test found ${expectedSegmentationModelFile} but timestamp not refreshed"
    cleanupOVMSDownload
    exit 1
  fi
else
  echo "Failed: --refresh option test expect model file not found ${expectedSegmentationModelFile}"
  cleanupOVMSDownload
  exit 1
fi

cleanupOVMSDownload