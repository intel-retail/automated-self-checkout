#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

CAMERA_ID=$1
PIPELINE_NUMBER=$2
LOG_DIRECTORY=$3
DURATION=$4
COMPLETE_INIT_DURATION=$5
PCM_DIRECTORY=/opt/intel/pcm/build/bin
STARTING_PORT=8080
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
GPU_DEVICE=$6
#system options: 
#core, xeon
SYSTEM=$7

#todo: need to add options to customize pipeline with ocr, barcode and classification options
#usage: ./docker-run.sh --platform core|xeon|dgpu.x --inputsrc RS_SERIAL_NUMBER|CAMERA_RTSP_URL|file:video.mp4|/dev/video0 [--classification_disabled] [ --ocr_disabled | --ocr [OCR_INTERVAL OCR_DEVICE] ] [ --barcode_disabled | --barcode [BARCODE_INTERVAL] ]

#GPU_DEVICE options are 
#dgpu (for flex and arc), soc for CPU/iGPU 

if grep -q "dgpu" <<< "$GPU_DEVICE"; then 
#if [ $GPU_DEVICE == "dgpu" ]
#then
	echo "device set to dgpu"
	DEVICE=$GPU_DEVICE
else
	DEVICE=$SYSTEM
fi
#echo "device set to $DEVICE"

# Handle bugs and "features" in intel_gpu_top JSON output
# https://gitlab.freedesktop.org/drm/igt-gpu-tools/-/issues/100
# https://gitlab.freedesktop.org/drm/igt-gpu-tools/-/blob/master/man/intel_gpu_top.rst?plain=1#L84
fix_igt_json() {
    sed -i -e s/^}$/},/ $1
    sed -i '$ s/.$//' $1
    tmp_file=/tmp/tmp.json
    echo '[' > $tmp_file
    cat $1 >> $tmp_file
    echo ']' >> $tmp_file
    mv $tmp_file $1
}

# NOTE: clean up log directory that is being reused
if [ -d $LOG_DIRECTORY ]; then rm -Rf $LOG_DIRECTORY; fi
if [ ! -d $LOG_DIRECTORY ]; then mkdir -p $LOG_DIRECTORY; fi

#remove previous meta data
rm -f results/*
#rm -f ../results/*


  #Add the video to test to the sample_media folder
  echo "Starting RTSP stream"
  ./camera-simulator.sh
  sleep 5
  echo "Starting pipelines. Device: $DEVICE"
  #docker-run needs to run in it's directory for the file paths to work
  cd ../
  for i in $( seq 0 $(($PIPELINE_NUMBER - 1)) )
  do
    if grep -q "dgpu" <<< "$GPU_DEVICE"; then 
      echo " ./docker-run.sh --platform $DEVICE --inputsrc $CAMERA_ID --ocr 5 GPU"
      ./docker-run.sh --platform $DEVICE --inputsrc $CAMERA_ID --ocr 5 GPU
    else
      echo "./docker-run.sh --platform $DEVICE --inputsrc $CAMERA_ID "
      ./docker-run.sh --platform $DEVICE --inputsrc $CAMERA_ID 
    fi
  done
  cd -

  sleep $COMPLETE_INIT_DURATION
  echo "Starting data collection"
    timeout "$DURATION"s sar 60 >& $LOG_DIRECTORY/cpu_usage.log &
    timeout "$DURATION"s free -s 60 >& $LOG_DIRECTORY/memory_usage.log &
    timeout "$DURATION"s sudo iotop -o -P -b -d 60 >& $LOG_DIRECTORY/disk_bandwidth.log &
    
    if [ $SYSTEM = "xeon" ]
    then
      timeout "$DURATION"s sudo $PCM_DIRECTORY/pcm-memory 60 -silent -nc -csv=$LOG_DIRECTORY/memory_bandwidth.csv &
    elif [ $SYSTEM = "core" ]
    then
      #echo "Add pcm for core here"
      timeout "$DURATION"s sudo $PCM_DIRECTORY/pcm 60 -silent -nc -nsys -csv=$LOG_DIRECTORY/pcm.csv &
    fi
        
    if grep -q "dgpu" <<< "$GPU_DEVICE" && [ $SYSTEM != "core" ]; then
      metrics=0,5,22,24,25
      if [ -e /dev/dri/renderD128 ]; then
        echo "==== Starting xpumanager capture (card 0) ===="
        timeout "$DURATION"s sudo xpumcli dump --rawdata --start -d 0 -m $metrics -j > ${LOG_DIRECTORY}/xpum0.json &
      fi
      if [ -e /dev/dri/renderD129 ]; then
        echo "==== Starting xpumanager capture (card 1) ===="
        timeout "$DURATION"s sudo xpumcli dump --rawdata --start -d 1 -m $metrics -j > ${LOG_DIRECTORY}/xpum1.json &
      fi
    else
      if [ -e /dev/dri/renderD128 ]; then
        echo "==== Starting intel_gpu_top  ===="
        timeout "$DURATION"s sudo intel_gpu_top -s 60000 -J > ${LOG_DIRECTORY}/igt1.json &
      fi
    fi


  sleep $DURATION
  
  echo "stopping server" 
  #./stop_server.sh
  sleep 10

  if [ -e ../results/r0.jsonl ]
  then
    sudo cp -r ../results .
    sudo mv results/pipeline* $LOG_DIRECTORY
  fi

    echo "fixing igt and xpum"
    if [ -e ${LOG_DIRECTORY}/igt1.json ]; then
      echo "fixing igt1.json"
      fix_igt_json ${LOG_DIRECTORY}/igt1.json
      #./fix_json.sh ${LOG_DIRECTORY}
    fi
    if [ -e ${LOG_DIRECTORY}/igt2.json ]; then
      echo "fixing igt2.json"
      fix_igt_json ${LOG_DIRECTORY}/igt2.json
    fi

    #move the xpumanager dump files
    devices=(0 1)
    for device in ${devices[@]}; do
      xpum_file=${LOG_DIRECTORY}/xpum${device}.json
      if [ -e $xpum_file ]; then
        echo "==== Stopping xpumanager collection (device ${device}) ===="
        task_id=$(jq '.task_id' $xpum_file)
        xpumcli dump --rawdata --stop $task_id
        sudo cp $(jq --raw-output '.dump_file_path' $xpum_file) ${LOG_DIRECTORY}/xpum${device}.csv
        #sudo cp $(jq --raw-output '.dump_file_path' $xpum_file) j_xpum${device}.csv
	sudo rm ${LOG_DIRECTORY}/xpum${device}.json
	cat ${LOG_DIRECTORY}/xpum${device}.csv | \
	  python3 -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))' > xpum${device}.json
	sudo mv xpum${device}.json ${LOG_DIRECTORY}/xpum${device}.json
      fi
    done


