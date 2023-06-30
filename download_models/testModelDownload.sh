#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

./modelDownload.sh

# $1 model directory
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

cleanupDownload() {
  echo 
  echo "cleaning up download files..."
  # remove downloaded files so it's re-testable
  rm -rf "$expectedEfficientnetDir"
  rm -rf "$expectedHorizontalTextDetection0001Dir"
  rm -rf "$expectedHorizontalTextDetection0002Dir"
  rm -rf "$expectedTextRec0012GPU"
  rm -rf "$expectedTextRec0014"
  # we don't delete the whole directory as there are some exisitng checked-in files
  rm ../configs/dlstreamer/models/2022/yolov5s/1/FP16-INT8/yolov5s.bin
  rm ../configs/dlstreamer/models/2022/yolov5s/1/FP16-INT8/yolov5s.xml
  rm ../configs/dlstreamer/models/2022/yolov5s/1/FP16/yolov5s.bin
  rm ../configs/dlstreamer/models/2022/yolov5s/1/FP16/yolov5s.xml
  rm ../configs/dlstreamer/models/2022/yolov5s/1/FP32-INT8/yolov5s.bin
  rm ../configs/dlstreamer/models/2022/yolov5s/1/FP32-INT8/yolov5s.xml
  rm ../configs/dlstreamer/models/2022/yolov5s/1/FP32/yolov5s.bin
  rm ../configs/dlstreamer/models/2022/yolov5s/1/FP32/yolov5s.xml
  rm ../configs/dlstreamer/models/2022/yolov5s/1/yolov5s.json

  echo "done."
}

modelDir="../configs/dlstreamer/models/2022/"

# Test efficientNet download
expectedEfficientnetDir=$modelDir"efficientnet-b0"
# Test efficientnet-b0.bin model file exists
testModelDownload "$expectedEfficientnetDir"/1/FP16-INT8 "efficientnet-b0.bin"
testModelDownload "$expectedEfficientnetDir"/1 "imagenet_2012.txt"
expectedEfficientnetModelFile=$expectedEfficientnetDir"/1/FP16-INT8/efficientnet-b0.bin"
if [ -f "$expectedEfficientnetModelFile" ]; then
  echo "Passed: found ${expectedEfficientnetModelFile}"
else
  echo "Failed: expect model file not found ${expectedEfficientnetModelFile}"
  exit 1
fi

timestamp_model=$(stat -c %Y "$expectedEfficientnetModelFile")
echo "$timestamp_model"

# Test horizontal text detection download
expectedHorizontalTextDetection0001Dir=$modelDir"horizontal-text-detection-0001"
testModelDownload $expectedHorizontalTextDetection0001Dir

# Test horizontal text detection download
expectedHorizontalTextDetection0002Dir=$modelDir"horizontal-text-detection-0002"
testModelDownload $expectedHorizontalTextDetection0002Dir

# Test text recognition 0012-GPU
expectedTextRec0012GPU=$modelDir"text-recognition-0012-GPU"
testModelDownload $expectedTextRec0012GPU

# Test text recognition 0014
expectedTextRec0014=$modelDir"text-recognition-0014"
testModelDownload $expectedTextRec0014

# Test Yolov5s download
expectedYolov5sDir=$modelDir"yolov5s/1/FP32"
testModelDownload $expectedYolov5sDir "yolov5s.bin"

# Test Yolov5s-INT8 download
expectedYolov5sINT8Dir=$modelDir"yolov5s/1/FP32-INT8"
testModelDownload $expectedYolov5sINT8Dir "yolov5s.bin"

echo 
echo "Test re-run modelDownloader and it should not re-download without --refresh option"
./modelDownload.sh
timestamp_model_rerun=$(stat -c %Y "$expectedEfficientnetModelFile")
echo "$timestamp_model_rerun"
if [ "$timestamp_model_rerun" -eq "$timestamp_model" ]; then
  echo "Passed: re-run modelDownloader and it didn't re-download files"
else
  echo "Failed: re-run modelDownloader and it re-download files"
  cleanupDownload
  exit 1
fi

echo
echo "Test --refresh option:"
# use refresh option to re-test:
./modelDownload.sh --refresh
if [ -f "$expectedEfficientnetModelFile" ]; then
  refresh_timestamp_model=$(stat -c %Y "$expectedEfficientnetModelFile")
  echo "$refresh_timestamp_model"
  if [ "$refresh_timestamp_model" -gt "$timestamp_model" ]; then
    echo "Passed: --refresh option test found ${expectedEfficientnetModelFile} and timestamp refreshed"
  else
    echo "Failed: --refresh option test found ${expectedEfficientnetModelFile} but timestamp not refreshed"
    cleanupDownload
    exit 1
  fi
else
  echo "Failed: --refresh option test expect model file not found ${expectedEfficientnetModelFile}"
  cleanupDownload
  exit 1
fi

cleanupDownload
