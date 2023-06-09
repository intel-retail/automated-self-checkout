#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

error() {
    printf '%s\n' "$1" >&2
    exit 1
}

show_help() {
        echo "
         usage: $0 
           --pipelines NUMBER_OF_PIPELINES | --stream_density TARGET_FPS [INCREMENTS]
           --logdir FULL_PATH_TO_DIRECTORY 
           --duration SECONDS (not needed when --stream_density is specified)
           --init_duration SECONDS 
           --platform core|xeon|dgpu.x 
           --inputsrc RS_SERIAL_NUMBER|CAMERA_RTSP_URL|file:video.mp4|/dev/video0 
           [--classification_disabled] 
           [ --ocr_disabled | --ocr [OCR_INTERVAL OCR_DEVICE] ] 
           [ --barcode_disabled | --barcode [BARCODE_INTERVAL] ]
           [--realsense_enabled]

         Note: 
          1. dgpu.x should be replaced with targetted GPUs such as dgpu (for all GPUs), dgpu.0, dgpu.1, etc
          2. filesrc will utilize videos stored in the sample-media folder
          3. Set environment variable STREAM_DENSITY_MODE=1 for starting single container stream density testing
          4. Set environment variable RENDER_MODE=1 for displaying pipeline and overlay CV metadata
          5. Stream density can take two parameters: first one is for target fps, a float type value, and
             the second one is increment integer of pipelines and is optional (in which case the increments will be dynamically adjusted internally)
        "
}

OPTIONS_TO_SKIP=0
DOCKER_RUN_ARGS=""

get_options() {
    while :; do
      case $1 in
        -h | -\? | --help)
          show_help
          exit
        ;;
        --pipelines)
          if [ -z "$2" ]; then
            error 'ERROR: "--pipelines" requires an integer.'        
          fi
            
          PIPELINE_COUNT=$2
          echo "pipelines: $PIPELINE_COUNT"
          OPTIONS_TO_SKIP=$(( $OPTIONS_TO_SKIP + 1 ))
          shift
          ;;
        --stream_density)
          if [ -z "$2" ]; then
            error 'ERROR: "--stream_density" requires an integer for target fps.'
          fi

          STREAM_DENSITY_INCREMENTS=""
          PIPELINE_COUNT=1
          STREAM_DENSITY_FPS=$2
          if [[ "$3" =~ ^--.* ]]; then
            echo "INFO: --stream_density no increment number configured; will be dynamically adjusted internally"
          else
            STREAM_DENSITY_INCREMENTS=$3
            OPTIONS_TO_SKIP=$(( $OPTIONS_TO_SKIP + 1 ))
            shift
          fi
          echo "stream_density: target fps = $STREAM_DENSITY_FPS  increments = $STREAM_DENSITY_INCREMENTS"
          OPTIONS_TO_SKIP=$(( $OPTIONS_TO_SKIP + 1 ))
          shift
          ;;
        --logdir)
          if [ -z "$2" ]; then
            error 'ERROR: "--logdir" requires an path to a directory.'        
          fi
            
          LOG_DIRECTORY=$2
          echo "logdir: $LOG_DIRECTORY"
          OPTIONS_TO_SKIP=$(( $OPTIONS_TO_SKIP + 1 ))
          shift
          ;;
        --duration)
          if [ -z "$2" ]; then
            error 'ERROR: "--duration" requires an integer.'        
          fi
            
          DURATION=$2
          echo "duration: $DURATION"
          OPTIONS_TO_SKIP=$(( $OPTIONS_TO_SKIP + 1 ))
          shift
          ;;
        --init_duration)
          if [ -z "$2" ]; then
            error 'ERROR: "--init_duration" requires an integer.'        
          fi
          
          OPTIONS_TO_SKIP=$(( $OPTIONS_TO_SKIP + 1 ))
          COMPLETE_INIT_DURATION=$2
          echo "init_duration: $COMPLETE_INIT_DURATION"
          shift
          ;;
        --*)
          DOCKER_RUN_ARGS="$DOCKER_RUN_ARGS $1"
          ;;
        ?*)
          DOCKER_RUN_ARGS="$DOCKER_RUN_ARGS $1"
          ;;
        *)
          break
          ;;
        esac

        OPTIONS_TO_SKIP=$(( $OPTIONS_TO_SKIP + 1 ))
        shift

    done
}


# USAGE: 
# 1. PLATFORM: core|xeon|dgpu.x
# 2. INPUT SOURCE: RS_SERIAL_NUMBER|CAMERA_RTSP_URL|file:video.mp4|/dev/video0
# 3. CLASSIFICATION: enabled|disabled
# 4. OCR: disabled|OCR_INTERVAL OCR_DEVICE
# 5. BARCODE: disabled|BARCODE_INTERVAL
# 6. REALSENSE: enabled|disabled
# 7. PIPELINE_NUMBER: the number of pipelines to start or specify MAX and a stream density benchmark will be performed with a 15 fps target per pipeline
# 8. LOG_DIRECTORY: the location to store all the log files. The consolidation script will look for directories within the top level directory and process the results in each one so the user will want to keep in mind this structure when creating the log directory. For example, for multiple videos with different number of objects, a log_directory would look like: yolov5s_6330N/object1_mixed. Whatever is meaningful for the test run.
# 9. DURATION: the amount of time to run the data collection
# 10 COMPLETE_INIT_DURATION: the amount of time to allow the system to settle prior to starting the data collection.

# load benchmark params
if [ -z $1 ]
then
        show_help
fi
get_options "$@"

# load docker-run params
shift $OPTIONS_TO_SKIP
# the following syntax for arguments is meant to be re-splitting for correctly used on all $DOCKER_RUN_ARGS
# shellcheck disable=SC2068
set -- $@ $DOCKER_RUN_ARGS
echo "arguments passing to get-optons.sh" "$@"
source ../get-options.sh "$@"

# set performance mode
echo "Setting scaling_governor to perf mode"
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# clean log directory that is being reused
if [ -d $LOG_DIRECTORY ]; then rm -Rf $LOG_DIRECTORY; fi

if [ ! -d $LOG_DIRECTORY ]; then mkdir -p $LOG_DIRECTORY; fi

# clean previous meta data
rm -f results/*
rm -f ../results/*

# NOTE: pcm-memory and pcm-power only support xeon platform. Need to use pcm for core platform
# NOTE: need to separate into 2 run for xeon as pcm-power and pcm-memory cannot run in parallel
is_xeon=`lscpu | grep -i xeon | wc -l`
if [ "$is_xeon"  == "1"  ]
then
        run_index=2
else
        run_index=1
fi

distributed=0
echo "RunIndex $run_index"
for test_run in $( seq 0 $(($run_index - 1)) )
do
  echo "Entered loop" 
  # Start camera-simulator if rtsp is requested
  if grep -q "rtsp" <<< "$INPUTSRC"; then
    echo "Starting RTSP stream"
    ./camera-simulator.sh
    sleep 5
  fi
  echo "Starting workload(s)"
  

  source get-gpu-info.sh
  NUM_GPU=0
  if [ "$HAS_FLEX_140" == 1 ]
  then
    NUM_GPU=$GPU_NUM_140
  elif [ "$HAS_FLEX_170" == 1 ]
  then
    NUM_GPU=$GPU_NUM_170
  fi

  # docker-run needs to run in it's directory for the file paths to work
  cd ../
#  pwd

  echo "DEBUG: docker-run.sh" "$@"

  for pipelineIdx in $( seq 0 $(($PIPELINE_COUNT - 1)) )
  do
    if [ -z "$STREAM_DENSITY_FPS" ]; then 
      #pushd ..
      echo "Starting pipeline$pipelineIdx"
      if [ "$CPU_ONLY" != 1 ] && ([ "$HAS_FLEX_140" == 1 ] || [ "$HAS_FLEX_170" == 1 ])
      then
          if [ "$NUM_GPU" != 0 ]
          then
            gpu_index=$(expr $pipelineIdx % $NUM_GPU)
            # replacing the value of --platform with dgpu.$gpu_index for flex case
            orig_args=("$@")
            for ((i=0; i < $#; i++))
            do
              if [ "${orig_args[i]}" == "--platform" ]
              then
                arrgpu=(${orig_args[i+1]//./ })
                TARGET_GPU_NUMBER=${arrgpu[1]}
                if [ -z "$TARGET_GPU_NUMBER" ] || [ "$distributed" == 1 ]; then
                  set -- "${@:1:i+1}" "dgpu.$gpu_index" "${@:i+3}"
                 distributed=1
                fi
                break
              fi
            done
            LOW_POWER=$LOW_POWER ./docker-run.sh "$@"
          else
            echo "Error: NUM_GPU is 0, cannot run"
            exit 1
          fi
      else
          CPU_ONLY=$CPU_ONLY LOW_POWER=$LOW_POWER ./docker-run.sh "$@"
      fi
      sleep 1
      #popd
    else
      echo "Starting stream density benchmarking"
      #cleanup any residual containers
      sids=($(docker ps  --filter="name=automated-self-checkout" -q -a))
      if [ -z "$sids" ]
      then
        echo "no dangling docker containers to clean up"
      else
        for sid in "${sids[@]}"
        do
          echo "cleaning up dangling container $sid"
          docker rm $sid -f
        done
      fi

      DURATION=0
      #pushd ..
      #echo "Cur dir: `pwd`"
      # Sync sleep in stream density script and platform metrics data collection script
      CPU_ONLY=$CPU_ONLY LOW_POWER=$LOW_POWER COMPLETE_INIT_DURATION=$COMPLETE_INIT_DURATION \
      STREAM_DENSITY_FPS=$STREAM_DENSITY_FPS STREAM_DENSITY_INCREMENTS=$STREAM_DENSITY_INCREMENTS \
      STREAM_DENSITY_MODE=1 ./docker-run.sh "$@"
      #popd
    fi
  done
  cd -

  echo "Waiting for init duration to complete..."
  sleep $COMPLETE_INIT_DURATION

  # launch log file monitor to detect if any pipeline stall happening
  POLLING_INTERVAL=2
  ./log_time_monitor.sh ../results/ $POLLING_INTERVAL $PIPELINE_COUNT > $LOG_DIRECTORY/log_time_monitor$test_run.log &
  log_time_monitor_pid=$!

  SOURCE_DIR=`pwd`
  echo $SOURCE_DIR

  if [ $test_run -eq 0 ]
  then
    docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -e test_run=$test_run -e LOG_DIRECTORY=$LOG_DIRECTORY -e SOURCE_DIR=$SOURCE_DIR -v $SOURCE_DIR/results:/tmp/results -v $SOURCE_DIR/$LOG_DIRECTORY:/$LOG_DIRECTORY --net=host --privileged benchmark:dev bash -c "./collect_platform_metrics.sh $DURATION $LOG_DIRECTORY $PLATFORM"
  else
    docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -e test_run=$test_run -e LOG_DIRECTORY=$LOG_DIRECTORY -e SOURCE_DIR=$SOURCE_DIR -v $SOURCE_DIR/results:/tmp/results -v $SOURCE_DIR/$LOG_DIRECTORY:/$LOG_DIRECTORY --net=host --privileged benchmark:dev bash -c "./collect_platform_metrics.sh $DURATION $LOG_DIRECTORY $PLATFORM --xeon-memory-only"
  fi

  if [ -z "$STREAM_DENSITY_FPS" ] 
  then
        echo "Waiting $DURATION seconds for workload to finish"
  else
        echo "Waiting for workload(s) to finish..."
        while [ 1 == 1 ]
        do
          # since there is no longer --rm automatically remove docker-run containers
          # we want to remove those first if any:
          exitedIds=$(docker ps  -f name=automated-self-checkout -f status=exited -q -a)
          if [ ! -z "$exitedIds" ]
          then
            docker rm "$exitedIds"
          fi

          sids=$(docker ps  --filter="name=automated-self-checkout" -q -a)
          #echo "sids: $sids"
          stream_workload_running=`echo "$sids" | wc -w`
          #echo "stream workload_running: $stream_workload_running"
          if (( $(echo $stream_workload_running 0 | awk '{if ($1 == $2) print 1;}') ))
          then
                #echo "DEBUG: quitting.."
                break
          fi
          # there are still some running automated-self-checkout containers, waiting for them to be finished...
          sleep 1
        done
  fi

  echo "workloads finished..."
  if [ -e ../results/r0.jsonl ]
  then
    sudo ./copy-platform-metrics.sh $LOG_DIRECTORY
    sudo python3 ./results_parser.py >> meta_summary.txt
    sudo mv meta_summary.txt $LOG_DIRECTORY
  fi


 sleep 2
 ./stop_server.sh
 sleep 5

done  # loop for test runs