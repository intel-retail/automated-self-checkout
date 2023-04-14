#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

get_gpu_devices() {
	has_gpu=0
	has_any_intel_server_gpu=`dmesg | grep -i "class 0x038000" | grep "8086"`
	has_flex_170=`echo "$has_any_intel_server_gpu" | grep -i "56C0"`
	has_flex_140=`echo "$has_any_intel_server_gpu" | grep -i "56C1"`

	if [ -z "$has_any_intel_server_gpu" ] 
	then
		echo "Error: No Intel GPUs found"
		return
	fi
	echo "GPU exists!"

	if [ ! -z "$has_flex_140" ]
	then
		HAS_FLEX_140=1
		GPU_NUM_140=`echo "$has_flex_140" | wc -l`
	fi
	if [ ! -z "$has_flex_170" ]
  then
		HAS_FLEX_170=1
		GPU_NUM_170=`echo "$has_flex_170" | wc -l`
	fi

	echo "HAS_FLEX_140=$HAS_FLEX_140, HAS_FLEX_170=$HAS_FLEX_170, GPU_NUM_140=$GPU_NUM_140, GPU_NUM_170=$GPU_NUM_170"
}

CAMERA_ID=$1
PIPELINE_NUMBER=$2
LOG_DIRECTORY=$3
DURATION=$4
COMPLETE_INIT_DURATION=$5
PCM_DIRECTORY=/opt/intel/pcm/build/bin
STARTING_PORT=8080
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
GPU_DEVICE=dgpu
#system options: 
#core, xeon
SYSTEM=xeon
REALSENSE_ENABLED=$6

#todo: need to add options to customize pipeline with ocr, barcode and classification options
#usage: ./docker-run.sh --platform core|xeon|dgpu.x --inputsrc RS_SERIAL_NUMBER|CAMERA_RTSP_URL|file:video.mp4|/dev/video0 [--classification_disabled] [ --ocr_disabled | --ocr [OCR_INTERVAL OCR_DEVICE] ] [ --barcode_disabled | --barcode [BARCODE_INTERVAL] ]

#GPU_DEVICE options are 
#dgpu (for flex and arc), soc for CPU/iGPU 

if grep -q "dgpu" <<< "$GPU_DEVICE"; then 
	echo "device set to dgpu"
	DEVICE=$GPU_DEVICE
else
	echo "error: should be always dgpu for flex devices"
  exit 1
fi

#NOTE: clean up log directory that is being reused
if [ -d $LOG_DIRECTORY ]; then rm -Rf $LOG_DIRECTORY; fi

if [ ! -d $LOG_DIRECTORY ]; then mkdir -p $LOG_DIRECTORY; fi

#remove previous meta data
rm -f results/*
rm -f ../results/*

HAS_FLEX_140=0
HAS_FLEX_170=0
get_gpu_devices

NUM_GPU=0
if [ "$HAS_FLEX_140" == 0 ] && [ "$HAS_FLEX_170" == 0 ]
then
  echo "Error: could not find the flex device hardware"
  exit 1
elif [ "$HAS_FLEX_140" == 1 ]
then
  NUM_GPU=$GPU_NUM_140
else
  NUM_GPU=$GPU_NUM_170
fi

if [ "$NUM_GPU" == 0 ]
then
  echo "Error: NUM_GPU is 0"
  exit 1
fi

# NOTE: pcm-memory and pcm-power only support xeon platform. Need to use pcm for core platform
# NOTE: need to separate into 2 run for xeon as pcm-power and pcm-memory cannot run in parallel
for test_run in $( seq 0 $((1)) )
do
  
  #Add the video to test to the sample_media folder
  echo "Starting RTSP stream"
  ./camera-simulator.sh
  sleep 5
  echo "Starting pipelines. Device: $DEVICE"
  #docker-run needs to run in it's directory for the file paths to work
  cd ../

  for i in $( seq 0 $(($PIPELINE_NUMBER - 1)) )
  do
    # distributed the pipeline workloads to each gpu alternatively
    gpu_index=$(expr $i % $NUM_GPU)
    echo " ./docker-run.sh --platform dgpu.$gpu_index --inputsrc $CAMERA_ID --ocr 5 GPU $REALSENSE_ENABLED"
    ./docker-run.sh --platform dgpu.$gpu_index --inputsrc $CAMERA_ID --ocr 5 GPU $REALSENSE_ENABLED
    statusCode=$?
    if [ "$statusCode" != 0 ]; then
      echo "Error: failed to launch pipeline $i for dgpu.$gpu_index with exit code $statusCode"
    fi
  done
  cd -

  sleep $COMPLETE_INIT_DURATION
  echo "Starting data collection"
  #if this is the first run, collect all the metrics
  if [ $test_run -eq 0 ]
  then
    timeout "$DURATION"s sar 1 >& $LOG_DIRECTORY/cpu_usage.log &
    timeout "$DURATION"s free -s 1 >& $LOG_DIRECTORY/memory_usage.log &
    timeout "$DURATION"s sudo iotop -o -P -b >& $LOG_DIRECTORY/disk_bandwidth.log &
    
    timeout "$DURATION"s sudo $PCM_DIRECTORY/pcm-power >& $LOG_DIRECTORY/power_usage.log &    
    
    metrics=0,5,22,24,25
    if [ -e /dev/dri/renderD128 ]; then
      echo "==== Starting xpumanager capture (card 0) ===="
      timeout "$DURATION"s sudo xpumcli dump --rawdata --start -d 0 -m $metrics -j > ${LOG_DIRECTORY}/xpum0.json &
    fi
    if [ -e /dev/dri/renderD129 ]; then
      echo "==== Starting xpumanager capture (card 1) ===="
      timeout "$DURATION"s sudo xpumcli dump --rawdata --start -d 1 -m $metrics -j > ${LOG_DIRECTORY}/xpum1.json &
    fi
  #if this is the second run, collect memory bandwidth data only
  else
    timeout "$DURATION"s sudo $PCM_DIRECTORY/pcm-memory 1 -silent -nc -csv=$LOG_DIRECTORY/memory_bandwidth.csv &
  fi
  

  sleep $DURATION
  echo "stopping server" 
  ./stop_server.sh
    
  if [ -e ../results/r0.jsonl ]
  then
    sudo cp -r ../results .
    sudo mv results/pipeline* $LOG_DIRECTORY
    sudo python3 ./results_parser.py >> meta_summary.txt
    sudo mv meta_summary.txt $LOG_DIRECTORY
  fi

  echo "test_run is: $test_run" 
  if [ $test_run -eq 0 ]
  then
    echo "fixing xpum"
    #move the xpumanager dump files
    devices=(0 1)
    for device in ${devices[@]}; do
      xpum_file=${LOG_DIRECTORY}/xpum${device}.json
      if [ -e $xpum_file ]; then
        echo "==== Stopping xpumanager collection (device ${device}) ===="
        task_id=$(jq '.task_id' $xpum_file)
        xpumcli dump --rawdata --stop $task_id
        sudo cp $(jq --raw-output '.dump_file_path' $xpum_file) ${LOG_DIRECTORY}/xpum${device}.csv
        sudo rm ${LOG_DIRECTORY}/xpum${device}.json
        cat ${LOG_DIRECTORY}/xpum${device}.csv | \
        python3 -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))' > xpum${device}.json
        sudo mv xpum${device}.json ${LOG_DIRECTORY}/xpum${device}.json
      fi
    done
  fi

  sleep 10

done
