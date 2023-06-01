#!/bin/bash -e
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

COMMAND="start"
SOURCE_DIR=$(dirname $(dirname "$(readlink -f "$0")"))
CAMERAS=
FILES=


get_options() {
    while :; do
        case $1 in
        -h | -\? | --help)
            show_help
            exit
            ;;
        --command)
            if [ "$2" ]; then
                COMMAND=$2
                shift
            else
                error 'ERROR: "--command" requires an argument.'
            fi
            ;;
        --cameras)
            if [ "$2" ]; then
                CAMERAS=$2
                shift
            else
                error 'ERROR: "--cameras" requires an argument.'
            fi
            ;;
        --files)
            if [ "$2" ]; then
                FILES=$2
                if [[ ! -e $SOURCE_DIR/sample-media/$2 ]]; then
                    echo "File $2 does not exist"
                    exit 1
                fi
                shift
            else
                error 'ERROR: "--files" requires an argument.'
            fi
            ;;
        --)
            shift
            break
            ;;
        -?*)
            error 'ERROR: Unknown option: ' $1
            ;;
        ?*)
            error 'ERROR: Unknown option: ' $1
            ;;
        *)
            break
            ;;
        esac

        shift
    done

}

show_help() {
    echo "usage: camera-simulator.sh"
    echo "  [--command start,stop]"
    echo "  [--cameras number of cameras]"
    echo "  [--files comma seperated list of files within sample-media]"
    exit 0
}

get_options "$@"

if [ -z "$COMMAND" ]; then
    COMMAND="START"
fi

if [ "${COMMAND,,}" = "start" ]; then

    if [ -z "$FILES" ]; then
	    cd $SOURCE_DIR/sample-media
	    FILES=( *.mp4 )
    else
	    IFS=','; FILES=( $FILES ); unset IFS;
    fi

    if [ -z "$CAMERAS" ]; then
	    CAMERAS=${#FILES[@]}
    fi

    cd $SOURCE_DIR/camera-simulator

    docker run --rm -t --network=host --name camera-simulator aler9/rtsp-simple-server >rtsp_simple_server.log.txt  2>&1 &
    index=0
    while [ $index -lt $CAMERAS ]
    do
	      for file in "${FILES[@]}"
	      do
		  echo "Starting camera: rtsp://127.0.0.1:8554/camera_$index from $file"
		  docker run -t --rm --name camera-simulator$index --entrypoint ffmpeg --network host -v $SOURCE_DIR/sample-media:/home/pipeline-server/sample-media openvino/ubuntu20_data_runtime:2021.4.2 -nostdin -re -stream_loop -1 -i /home/pipeline-server/sample-media/$file -c copy -f rtsp -rtsp_transport tcp rtsp://localhost:8554/camera_$index >/dev/null 2>&1 &
		  ((index+=1))
		  if [ $CAMERAS -le $index ]; then
		      break
		  fi
		  sleep 1
	      done
    done

elif [ "${COMMAND,,}" = "stop" ]; then
    docker kill camera-simulator 2> /dev/null
fi

