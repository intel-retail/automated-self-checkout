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

start_xpum() {
    metrics=0,5,22,24,25
    device=$1
    echo "==== Starting xpumanager capture (gpu $device) ===="
    let xpumPort=29990+$device
    docker run -itd -v /sys/firmware/acpi/tables/MCFG:/pcm/sys/firmware/acpi/tables/MCFG:ro -v /proc/bus/pci/:/pcm/proc/bus/pci/ -v /proc/sys/kernel/nmi_watchdog:/pcm/proc/sys/kernel/nmi_watchdog -v $SOURCE_DIR/$LOG_DIRECTORY:/$cpuOutputDir  --cap-drop ALL --cap-add CAP_SYS_ADMIN --user root -e XPUM_REST_NO_TLS=1 --device /dev/dri:/dev/dri --device /dev/cpu:/dev/cpu --name=xpum$device benchmark:xpu 
    sleep 5
    docker exec xpum$device bash -c "xpumcli dump --rawdata --start -d $device -m $metrics -j"
}

DURATION=$1
LOG_DIRECTORY=$2
PLATFORM=$3
PCM_DIRECTORY=/opt/intel/pcm-bin/bin
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
    cpuOutputDir=/tmp/xpumdump/
    metrics=0,5,22,24,25
    device=0
    # Check for up to 4 GPUs e.g. 300W max 
    if [ -e /dev/dri/renderD128 ]; then
      device=0
      echo "==== Found device $device ===="
      start_xpum "$device"
    fi
    if [ -e /dev/dri/renderD129 ]; then
      device=1
      echo "==== Found device $device ===="
      start_xpum "$device"
    fi
    if [ -e /dev/dri/renderD130 ]; then
      device=2
      echo "==== Found device $device ===="
      start_xpum "$device"
    fi
    if [ -e /dev/dri/renderD131 ]; then
      device=3
      echo "==== Found device $device ===="
      start_xpum "$device"
    fi
  # DGPU pipeline and  Arc GPU Metrics
  elif [ "$PLATFORM" == "dgpu" ] && [ $HAS_ARC == 1 ]
  then
    echo "==== Starting igt arc ===="
    # Arc is always on Core platform and although its GPU.1, the IGT device is actually 0
    # Collecting both 
    timeout $DURATION docker run -v $SOURCE_DIR/$LOG_DIRECTORY:/$LOG_DIRECTORY -e LOG_DIRECTORY=$LOG_DIRECTORY -itd --privileged benchmark:igt bash -c "/usr/local/bin/intel_gpu_top -d pci:card=0 -J > $LOG_DIRECTORY/igt0.json"
    timeout $DURATION docker run -v $SOURCE_DIR/$LOG_DIRECTORY:/$LOG_DIRECTORY -e LOG_DIRECTORY=$LOG_DIRECTORY -itd --privileged benchmark:igt bash -c "/usr/local/bin/intel_gpu_top -d pci:card=1 -J > $LOG_DIRECTORY/igt1.json"

  # CORE pipeline and iGPU/Arc GPU Metrics
  elif [ "$PLATFORM" == "core" ]
  then
    if [ $HAS_ARC == 1 ]
    then
      echo "==== Starting igt arc ===="
      # Core can only have at most 2 GPUs 
      timeout $DURATION docker run -v $SOURCE_DIR/$LOG_DIRECTORY:/$LOG_DIRECTORY -e LOG_DIRECTORY=$LOG_DIRECTORY -itd --privileged benchmark:igt bash -c "/usr/local/bin/intel_gpu_top -d pci:card=0 -J > $LOG_DIRECTORY/igt0.json"
      timeout $DURATION docker run -v $SOURCE_DIR/$LOG_DIRECTORY:/$LOG_DIRECTORY -e LOG_DIRECTORY=$LOG_DIRECTORY -itd --privileged benchmark:igt bash -c "/usr/local/bin/intel_gpu_top -d pci:card=1 -J > $LOG_DIRECTORY/igt1.json"
    else
      echo "==== Starting igt core ===="
      timeout $DURATION docker run -v $SOURCE_DIR/$LOG_DIRECTORY:/$LOG_DIRECTORY -e LOG_DIRECTORY=$LOG_DIRECTORY -itd --privileged benchmark:igt bash -c "/usr/local/bin/intel_gpu_top -d pci:card=0 -J > $LOG_DIRECTORY/igt0.json"
    fi    
  fi
#if this is the second run, collect memory bandwidth data only
else
  if [ "$is_xeon"  == "1"  ]
  then
    docker run -itd -v $SOURCE_DIR/$LOG_DIRECTORY:/$cpuOutputDir  --cap-drop ALL --cap-add CAP_SYS_ADMIN --user root -e XPUM_REST_NO_TLS=1 -e XPUM_EXPORTER_NO_AUTH=1 -e XPUM_EXPORTER_ONLY=1 --publish 127.0.0.1:$xpumPort:$xpumPort --device /dev/dri:/dev/dri --name=xpummemory intel/xpumanager:v1.0.0 
    sleep 5
    docker exec xpummemory bash -c "xpcm-memory 1 -silent -nc -csv=$LOG_DIRECTORY/memory_bandwidth.csv -j"
  fi 
fi

if [ "$DURATION" == "0" ]
then
      echo "Data collection running until max stream density is reached"
else
      echo "Data collection will run for $DURATION seconds"
fi
sleep $DURATION

echo "stopping platform data collection..."
pkill -f iotop
pkill -f free
pkill -f sar
pkill -f pcm-power
pkill -f pcm
pkill -f xpumcli
pkill -f intel_gpu_top
pkill -f pcm-memory
sleep 2

echo "test_run is: $test_run" 
if [ $test_run -eq 0 ]
then
  ./cleanup_gpu_metrics.sh $LOG_DIRECTORY
fi
