#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

testModelDownload() {
    if [ -d "$1" ]; then
      # Take action if $DIR exists. #
      # check if there is a 2nd parameter input as the filename
      if [ -n "$2" ]; then
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

cleanupDownload() {
  echo 
  echo "cleaning up opencv-ovms download files..."
  (
    cd ..
    make clean-models
  )

  echo "done clean up OVMS download."
}

echo
echo "CASE Test 1: happy path"
#download ovms models downloaded
./downloadModels.sh

modelOVMSDir="../models/"
localModelFolderName="yolov5s"
modelPrecisionFP16INT8=FP16-INT8
yolov5s="yolov5s"

# Test yolov5s download
expectedyolov5sDir=$modelOVMSDir$localModelFolderName
echo "$expectedyolov5sDir"
# Test yolov5s.bin model file exists
testModelDownload "$expectedyolov5sDir/$modelPrecisionFP16INT8/1" "$yolov5s.xml"
expectedyolov5sModelFile="$expectedyolov5sDir/$modelPrecisionFP16INT8/1/$yolov5s.xml"
if [ -f "$expectedyolov5sModelFile" ]; then
  echo "Passed: found ${expectedyolov5sModelFile}"
else
  echo "Failed: expect model file not found ${expectedyolov5sModelFile}"
  exit 1
fi

timestamp_ovms_model=$(stat -c %Z "$expectedyolov5sModelFile")

echo 
echo "CASE Test 2: re-run downloadModels and it should not re-download without --refresh option"
./downloadModels.sh
timestamp_model_rerun=$(stat -c %Z "$expectedyolov5sModelFile")
if [ "$timestamp_model_rerun" -eq "$timestamp_ovms_model" ]; then
  echo "Passed: re-run downloadModels and it didn't re-download files"
else
  echo "Failed: re-run downloadModels and it re-download files"
  cleanupDownload
  exit 1
fi

echo
echo "CASE Test 3: --refresh option"
# use refresh option to re-test:
./downloadModels.sh --refresh
if [ -f "$expectedyolov5sModelFile" ]; then
  refresh_timestamp_ovms_model=$(stat -c %Z "$expectedyolov5sModelFile")
  echo "DEBUG: refresh_timestamp_ovms_model: $refresh_timestamp_ovms_model"
  if [ "$refresh_timestamp_ovms_model" -gt "$timestamp_ovms_model" ]; then
    echo "Passed: --refresh option test found ${expectedyolov5sModelFile} and timestamp refreshed"
  else
    echo "Failed: --refresh option test found ${expectedyolov5sModelFile} but timestamp not refreshed"
    cleanupDownload
    exit 1
  fi
else
  echo "Failed: --refresh option test expect model file not found ${expectedyolov5sModelFile}"
  cleanupDownload
  exit 1
fi

cleanupDownload