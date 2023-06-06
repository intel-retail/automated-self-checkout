#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

min_expected=2
target_fps=14.9
testDir=mytest1
increment_hint=5

echo "testcase: minimum ${min_expected} streams expected without increments hint"
# testing for no increments hint
sudo ./benchmark.sh --stream_density $target_fps --logdir "$testDir" --duration 120 --init_duration 60 \
  --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --workload dlstreamer --ocr_disabled --barcode_disabled --classification_disabled

statusCode=$?
if [ $statusCode -ne 0 ]
then
  echo "test failed: expecting get status code 0 but found $statusCode"
else
  # Max stream density achieved for target FPS 12 is at least 1
  res=$(grep -i -Eo "Max stream density achieved for target FPS ([0-9]+(.[0-9]+)*) is ([0-9])+" ../results/stream_density.log  | awk -F ' ' '{print $10}')

  if [ -z "${res}" ]; then
    echo "test fialed: maximum pipeline numbers not found"
  elif [ "${res}" -ge "${min_expected}" ]; then
    echo "test passed: maximum pipeline number = ${res}"
  else
    echo "test failed: unable to reach the min. ${min_expected} streams as maximum pipeline number = ${res}"
  fi
fi

sudo rm -rf "$testDir"

echo
echo "testcase: minimum ${min_expected} streams expected with increments hint"
#testing for core system with rtsp, you may need to edit the input source if rtsp is different for camera device
sudo ./benchmark.sh --stream_density $target_fps $increment_hint --logdir "$testDir" --duration 120 --init_duration 60 \
  --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --workload dlstreamer --ocr_disabled --barcode_disabled --classification_disabled

statusCode=$?
if [ $statusCode -ne 0 ]
then
  echo "test failed: expecting get status code 0 but found $statusCode"
else
  # Max stream density achieved for target FPS 12 is at least 1
  res=$(grep -i -Eo "Max stream density achieved for target FPS ([0-9]+(.[0-9]+)*) is ([0-9])+" ../results/stream_density.log  | awk -F ' ' '{print $10}')

  if [ -z "${res}" ]; then
    echo "test fialed: maximum pipeline numbers not found"
  elif [ "${res}" -ge "${min_expected}" ]; then
    echo "test passed: maximum pipeline number = ${res}"
  else
    echo "test failed: unable to reach the min. ${min_expected} streams as maximum pipeline number = ${res}"
  fi
fi

sudo rm -rf "$testDir"

echo 

