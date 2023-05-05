#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

show_help() {
      echo "
         usage: $0 DURATION LOG_DIRECTORY PLATFORM [--xeon-memory-only]         
        "
}

#echo "DEBUG: Params $@"

DURATION=$1
LOG_DIRECTORY=$2
PLATFORM=$3
#SOURCE_DIR=$(dirname "$(readlink -f "$0")")
PCM_DIRECTORY=/opt/intel/pcm/build/bin
source get-gpu-info.sh

test_run=0
if [ "$4" == "--xeon-memory-only" ]
then
  test_run=1
fi

is_xeon=`lscpu | grep -i xeon | wc -l`

echo "Starting platform data collection"
#if this is the first run, collect all the metrics
if [ $test_run -eq 0 ]
then
  echo "Starting main data collection"
  timeout "$DURATION" sar 1 >& $LOG_DIRECTORY/cpu_usage.log &
  timeout "$DURATION" free -s 1 >& $LOG_DIRECTORY/memory_usage.log &
  timeout "$DURATION" iotop -o -P -b >& $LOG_DIRECTORY/disk_bandwidth.log &
  
  if [ "$is_xeon"  == "1"  ]
  then
    echo "Starting xeon pcm-power collection"
    timeout "$DURATION" $PCM_DIRECTORY/pcm-power >& $LOG_DIRECTORY/power_usage.log &
  else
    timeout "$DURATION" $PCM_DIRECTORY/pcm 1 -silent -nc -nsys -csv=$LOG_DIRECTORY/pcm.csv &
    echo "DEBUG: pcm started collecting"
  fi
      
  # DGPU pipeline and Flex GPU Metrics
  if [ "$PLATFORM" == "dgpu" ] && [ $HAS_ARC == 0 ] 
  then
    metrics=0,5,22,24,25
    # Check for up to 4 GPUs e.g. 300W max 
    if [ -e /dev/dri/renderD128 ]; then
      echo "==== Starting xpumanager capture (gpu 0) ===="
      docker run -itd --rm -e SOURCE_DIR=$SOURCE_DIR -e LOG_DIRECTORY=$LOG_DIRECTORY -v $SOURCE_DIR/results:/tmp/results -v $SOURCE_DIR/$LOG_DIRECTORY:/$LOG_DIRECTORY --net=host --privileged intel/xpumanager:latest bash -c "xpumcli dump --rawdata --start -d 0 -m $metrics -j > ${LOG_DIRECTORY}/xpum0.json &"
    fi
    if [ -e /dev/dri/renderD129 ]; then
      echo "==== Starting xpumanager capture (gpu 1) ===="
      docker run -itd --rm -e SOURCE_DIR=$SOURCE_DIR -v $SOURCE_DIR/results:/tmp/results -v $SOURCE_DIR/$LOG_DIRECTORY:/$LOG_DIRECTORY --net=host --privileged intel/xpumanager:latest bash -c "xpumcli dump --rawdata --start -d 1 -m $metrics -j > ${LOG_DIRECTORY}/xpum0.json &"
    fi
    if [ -e /dev/dri/renderD130 ]; then
      echo "==== Starting xpumanager capture (gpu 2) ===="
      docker run -itd --rm -e SOURCE_DIR=$SOURCE_DIR -v $SOURCE_DIR/results:/tmp/results -v $SOURCE_DIR/$LOG_DIRECTORY:/$LOG_DIRECTORY --net=host --privileged intel/xpumanager:latest bash -c "xpumcli dump --rawdata --start -d 2 -m $metrics -j > ${LOG_DIRECTORY}/xpum0.json &"
    fi
    if [ -e /dev/dri/renderD131 ]; then
      echo "==== Starting xpumanager capture (gpu 4) ===="
      docker run -itd --rm -e SOURCE_DIR=$SOURCE_DIR -v $SOURCE_DIR/results:/tmp/results -v $SOURCE_DIR/$LOG_DIRECTORY:/$LOG_DIRECTORY --net=host --privileged intel/xpumanager:latest bash -c "xpumcli dump --rawdata --start -d 3 -m $metrics -j > ${LOG_DIRECTORY}/xpum0.json &"
    fi
  # DGPU pipeline and  Arc GPU Metrics
  elif [ "$PLATFORM" == "dgpu" ] && [ $HAS_ARC == 1 ]
  then
    echo "==== Starting igt arc ===="
    # Arc is always on Core platform and although its GPU.1, the IGT device is actually 0
    # Collecting both 
    timeout $DURATION docker run -v $SOURCE_DIR/results:/tmp/results -itd --privileged benchmark:igt bash -c "/usr/local/bin/intel_gpu_top -d pci:card=0 -J > /tmp/results/igt0.json"
    timeout $DURATION docker run -v $SOURCE_DIR/results:/tmp/results -itd --privileged benchmark:igt bash -c "/usr/local/bin/intel_gpu_top -d pci:card=1 -J > /tmp/results/igt1.json"

  # CORE pipeline and iGPU/Arc GPU Metrics
  elif [ "$PLATFORM" == "core" ]
  then
    if [ $HAS_ARC == 1 ]
    then
      echo "==== Starting igt arc ===="
      # Core can only have at most 2 GPUs 
      timeout $DURATION docker run -v $SOURCE_DIR/results:/tmp/results -itd --privileged benchmark:igt bash -c "/usr/local/bin/intel_gpu_top -d pci:card=0 -J > /tmp/results/igt0.json"
      timeout $DURATION docker run -v $SOURCE_DIR/results:/tmp/results -itd --privileged benchmark:igt bash -c "/usr/local/bin/intel_gpu_top -d pci:card=1 -J > /tmp/results/igt1.json"
    else
      echo "==== Starting igt core ===="
      timeout $DURATION docker run -v $SOURCE_DIR/results:/tmp/results -itd --privileged benchmark:igt bash -c "/usr/local/bin/intel_gpu_top -d pci:card=0 -J > /tmp/results/igt0.json"
    fi    
  fi
#if this is the second run, collect memory bandwidth data only
else
  if [ "$is_xeon"  == "1"  ]
  then
    timeout "$DURATION" $PCM_DIRECTORY/pcm-memory 1 -silent -nc -csv=$LOG_DIRECTORY/memory_bandwidth.csv &
  fi 
fi

if [ "$DURATION" == "0" ]
then
      echo "Data collection running until max stream density is reached"
else
      echo "Data collection will run for $DURATION seconds"
fi
sleep $DURATION

#echo "stopping docker containers" 
#./stop_server.sh
#echo "stopping data collection..."
#pkill -f iotop
#pkill -f free
#pkill -f sar
#pkill -f pcm-power
#pkill -f pcm
#pkill -f xpumcli
#pkill -f intel_gpu_top
#sleep 2

#if [ -e ../results/r0.jsonl ]
#then
#  echo "Copying data for collection scripts...`pwd`"

#  cp -r ../results .
#  mv results/igt* $LOG_DIRECTORY
#  mv results/pipeline* $LOG_DIRECTORY
#  python3 ./results_parser.py >> meta_summary.txt
#  mv meta_summary.txt $LOG_DIRECTORY
#else
#  echo "Warning no data found for collection!"