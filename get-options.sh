#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

error() {
    printf '%s\n' "$1" >&2
    exit 1
}

show_help() {
	echo "
         usage: PIPELINE_PROFILE=\"object_detection\" (or others from make list-profiles) [RENDER_MODE=0 or 1] [LOW_POWER=0 or 1] [CPU_ONLY=0 or 1]
                [DEVICE=\"CPU\" or other device] [MQTT=127.0.0.1:1883 if using MQTT broker] [COLOR_HEIGHT=1080] [COLOR_WIDTH=1920] [COLOR_FRAMERATE=15]
                sudo -E ./run.sh --platform core.x|xeon|dgpu.x --inputsrc RS_SERIAL_NUMBER|CAMERA_RTSP_URL|file:video.mp4|/dev/video0

         Note: 
         1.  dgpu.x should be replaced with targeted GPUs such as dgpu (for all GPUs), dgpu.0, dgpu.1, etc
         2.  core.x should be replaced with targeted GPUs such as core (for all GPUs), core.0, core.1, etc
         3.  filesrc will utilize videos stored in the sample-media folder
         4.  when using device camera like USB, put your correspondent device number for your camera like /dev/video2 or /dev/video4
         5.  Set environment variable STREAM_DENSITY_MODE=1 for starting pipeline stream density testing
         6.  Set environment variable RENDER_MODE=1 for displaying pipeline and overlay CV metadata
         7.  Set environment variable LOW_POWER=1 for using GPU usage only based pipeline for Core platforms
         8.  Set environment variable CPU_ONLY=1 for overriding inference to be performed on CPU only
         9.  Set environment variable PIPELINE_PROFILE=\"object_detection\" to run ovms pipeline profile object detection: values can be listed by \"make list-profiles\"
         10. Set environment variable STREAM_DENSITY_FPS=15.0 for setting stream density target fps value
         11. Set environment variable STREAM_DENSITY_INCREMENTS=1 for setting incrementing number of pipelines for running stream density
         12. Set environment variable DEVICE=\"CPU\" for setting device to use for pipeline run, value can be \"GPU\", \"CPU\", \"AUTO\", \"MULTI:GPU,CPU\"
         13. Set environment variable MQTT=127.0.0.1:1883 for exporting inference metadata to an MQTT broker.
         14. Set environment variable like COLOR_HEIGHT, COLOR_WIDTH, and COLOR_FRAMERATE(in FPS) for inputsrc RealSense camera use cases.
        "
}

while :; do
    case $1 in
    -h | -\? | --help)
        show_help
        exit
        ;;
    --platform)
        if [ "$2" ]; then
            if [ $2 == "xeon" ]; then
                PLATFORM=$2
                shift
            elif grep -q "core" <<< "$2"; then
                PLATFORM="core"
                arrgpu=(${2//./ })
                TARGET_GPU_NUMBER=${arrgpu[1]}
                if [ -z "$TARGET_GPU_NUMBER" ]; then
                    TARGET_GPU="GPU.0"
                    # TARGET_GPU_DEVICE="--privileged"
                else
                    TARGET_GPU_ID=$((128+$TARGET_GPU_NUMBER))
                    TARGET_GPU="GPU."$TARGET_GPU_NUMBER
                    TARGET_GPU_DEVICE="--device=/dev/dri/renderD"$TARGET_GPU_ID
                    TARGET_GPU_DEVICE_NAME="/dev/dri/renderD"$TARGET_GPU_ID
                fi
                echo "CORE"
                shift
            elif grep -q "dgpu" <<< "$2"; then			
                PLATFORM="dgpu"
                arrgpu=(${2//./ })
                TARGET_GPU_NUMBER=${arrgpu[1]}
                if [ -z "$TARGET_GPU_NUMBER" ]; then
                    TARGET_GPU="GPU.0"
                    # TARGET_GPU_DEVICE="--privileged"
                else
                    TARGET_GPU_ID=$((128+$TARGET_GPU_NUMBER))
                    TARGET_GPU="GPU."$TARGET_GPU_NUMBER
                    TARGET_GPU_DEVICE="--device=/dev/dri/renderD"$TARGET_GPU_ID
                    TARGET_GPU_DEVICE_NAME="/dev/dri/renderD"$TARGET_GPU_ID
                fi
                #echo "$PLATFORM $TARGET_GPU"
                shift	
            else
                error 'ERROR: "--platform" requires an argument core|xeon|dgpu.'
            fi
        else
                error 'ERROR: "--platform" requires an argument core|xeon|dgpu.'
        fi	    
        ;;
    --inputsrc)
        if [ "$2" ]; then
            INPUTSRC=$2
            shift
        else
            error 'ERROR: "--inputsrc" requires an argument RS_SERIAL_NUMBER|CAMERA_RTSP_URL|file:video.mp4|/dev/video0.'
        fi
        ;;
    -?*)
        error "ERROR: Unknown option $1"
        ;;
    ?*)
        error "ERROR: Unknown option $1"
        ;;
    *)
        break
        ;;
    esac

    shift

done

if [ -z $PLATFORM ] || [ -z $INPUTSRC ]
then
	#echo "Blanks: $1 $PLATFORM $INPUTSRC"
   	show_help
	exit 0
fi

echo "Device:"
echo $TARGET_GPU_DEVICE
