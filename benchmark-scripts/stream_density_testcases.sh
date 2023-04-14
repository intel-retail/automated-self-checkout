#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

#test case 1: minimum number of streams
min_expected=2
echo "testcase: minimum ${min_expected} streams expected"
#testing for core system with rtsp, you may need to edit the input source if rtsp is different for camera device
./stream_density.sh rtsp://127.0.0.1:8554/camera_1 core 14.5 > testoutput.txt 2>&1
res=$(grep -i -Eo "Max number of pipelines: ([0-9])" ./testoutput.txt  | awk -F ' ' '{print $5}')

if [ -z "${res}" ]; then
  echo "maximum pipeline numbers not found, test failed"
elif [ "${res}" -ge "${min_expected}" ]; then
  echo "test passed, maximum pipeline number = ${res}"
else
  echo "failed to reach the min. ${min_expected} streams as maximum pipeline number = ${res}"
fi

echo 

# test case 2: reach minimum target FPS
min_expected_fps=14
echo "testcase: min target fps = ${min_expected_fps}"
./stream_density.sh rtsp://127.0.0.1:8554/camera_1 core ${min_expected_fps} > testoutput2.txt 2>&1
max_pipelines=$(grep -i -Eo "Max number of pipelines: ([0-9])" ./testoutput2.txt  | awk -F ' ' '{print $5}')
fps_at_max_pipelines=$(grep -i -Eo "FPS for total number of pipeline ${max_pipelines}: ([0-9]+.[0-9]+)" ./testoutput2.txt | awk -F ' ' '{print $8}')
min_fps=""
if [ -z "${fps_at_max_pipelines}" ]; then
  echo "could not find the fps for max number of pipelines, trying to find the last fps"
  min_fps=$(grep -i -Eo "FPS for total number of pipeline ([0-9]+): ([0-9]+.[0-9]+)" ./testoutput2.txt | sort -r | head -1 | awk -F ' ' '{print $8}')
else
  min_fps=${fps_at_max_pipelines}
fi

if [ -z "${min_fps}" ]; then
  echo "minimum fps for pipelines not found, test failed"
elif [ 1 -eq "$(echo "${min_fps} >= ${min_expected_fps}" | bc)" ]; then
  echo "test passed, FPS for pipeline is greater than or equal to the minimum fps expected (${min_expected_fps}) = ${min_fps} and max. number of pipelines = ${max_pipelines}"
else
  echo "failed to reach the min. fps ${min_expected_fps} for maximum pipeline number = ${max_pipelines} and the actual fps = ${min_fps}"
fi

echo 

# test case 3: expected it cannot reach very high minimum target FPS
min_expected_fps=50
echo "testcase: min target fps = ${min_expected_fps}"
./stream_density.sh rtsp://127.0.0.1:8554/camera_1 core ${min_expected_fps} > testoutput.txt 2>&1
max_pipelines=$(grep -i -Eo "Max number of pipelines: ([0-9])" ./testoutput.txt  | awk -F ' ' '{print $5}')
min_fps=$(grep -i -Eo "FPS for total number of pipeline ([0-9]+): ([0-9]+.[0-9]+)" ./testoutput.txt | sort -r | head -1 | awk -F ' ' '{print $8}')

# expect case that we couldn't reach the target high FPS like over 30 or 50
if [ -z "${min_fps}" ]; then
  echo "minimum fps for pipelines not found, test failed"
elif [ 1 -eq "$(echo "${min_fps} < ${min_expected_fps}" | bc)" ]; then
  echo "test passed, FPS for pipeline is expected to be unable to reach the target FPS (${min_expected_fps}) = ${min_fps} and max. number of pipelines = ${max_pipelines}"
else
  echo "failed test and FPS exceeds the min. target fps ${min_expected_fps} for maximum pipeline number = ${max_pipelines} and the actual fps = ${min_fps}"
fi