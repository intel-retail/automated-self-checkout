#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

BARCODE_DISABLED=0
BARCODE_INTERVAL=5
OCR_INTERVAL=5
OCR_DEVICE=CPU
OCR_DISABLED=0
CLASSIFICATION_DISABLED=0
OCR_SPECIFIED=0

error() {
    printf '%s\n' "$1" >&2
    exit 1
}

show_help() {
	echo "
         usage: ./run.sh --platform core.x|xeon|dgpu.x --inputsrc RS_SERIAL_NUMBER|CAMERA_RTSP_URL|file:video.mp4|/dev/video0 [--classification_disabled] [ --ocr_disabled | --ocr [OCR_INTERVAL OCR_DEVICE] ] [ --barcode_disabled | --barcode [BARCODE_INTERVAL] ] [--realsense_enabled]

         Note: 
         1. dgpu.x should be replaced with targeted GPUs such as dgpu (for all GPUs), dgpu.0, dgpu.1, etc
         2. core.x should be replaced with targeted GPUs such as core (for all GPUs), core.0, core.1, etc
         3. filesrc will utilize videos stored in the sample-media folder
         4. Set environment variable STREAM_DENSITY_MODE=1 for starting pipeline stream density testing
         5. Set environment variable RENDER_MODE=1 for displaying pipeline and overlay CV metadata
         6. Set environment variable LOW_POWER=1 for using GPU usage only based pipeline for Core platforms
         7. Set environment variable CPU_ONLY=1 for overriding inference to be performed on CPU only
         8. Set environment variable PIPELINE_PROFILE=\"object_detection\" to run ovms pipeline profile object detection: values can be listed by \"make list-profiles\"
         9. Set environment variable STREAM_DENSITY_FPS=15.0 for setting stream density target fps value
         10. Set environment variable STREAM_DENSITY_INCREMENTS=1 for setting incrementing number of pipelines for running stream density
         11. Set environment variable DEVICE=\"CPU\" for setting device to use for pipeline run, value can be \"GPU\", \"CPU\", \"AUTO\", \"MULTI:GPU,CPU\"
         12. Set environment variable MQTT=127.0.0.1:1883 for exporting inference metadata to an MQTT broker.
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
    --classification_disabled)
        CLASSIFICATION_DISABLED=1
        ;;
    --ocr_disabled)
        OCR_DISABLED=1
        ;;
    --barcode_disabled)
        BARCODE_DISABLED=1
        ;;
    --realsense_enabled)
        REALSENSE_ENABLED=1
        ;;
    --ocr)
        if [ "$2" ]; then
            OCR_INTERVAL=$2
        else
            error 'ERROR: "--ocr" requires an argument [OCR_INTERVAL OCR_DEVICE].'
        fi
        if [ "$3" ]; then
            OCR_DEVICE=$3
            shift 2
        else
            error 'ERROR: "--ocr" requires an argument [OCR_INTERVAL] [OCR_DEVICE].'
        fi
        OCR_SPECIFIED=1
        ;;
    --barcode)
        if [ "$2" ]; then
            BARCODE_INTERVAL=$2
            shift 1
        else
            error 'ERROR: "--barcode" requires an argument [BARCODE_INTERVAL].'
        fi
        ;;
	--color-width)
        if [ "$REALSENSE_ENABLED" != 1 ]; then
            error 'ERROR: "--color-width requires realsense_enable flag'
        else
            if [ "$2" ]; then
                COLOR_WIDTH=$2
                shift 1
            else
                error 'ERROR: "--color-width" requires an argument [COLOR_WIDTH].'
            fi
        fi
        ;;
    --color-height)
        if [ "$REALSENSE_ENABLED" != 1 ]; then
            error 'ERROR: "--color-height requires realsense_enable flag'
        else
            if [ "$2" ]; then
                COLOR_HEIGHT=$2
                shift 1
            else
                error 'ERROR: "--color-height" requires an argument [COLOR_HEIGHT].'
            fi
        fi
        ;;
    --color-framerate)
        if [ "$REALSENSE_ENABLED" != 1 ]; then
            error 'ERROR: "--color-framerate requires realsense_enable flag'
        else
            if [ "$2" ]; then
                COLOR_FRAMERATE=$2
                shift 1
            else
                error 'ERROR: "--color-framerate" requires an argument [COLOR_FRAMERATE].'
            fi
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

if [ $OCR_DISABLED == 0 ] && [ $PLATFORM=="dgpu" ] && [ $OCR_SPECIFIED == 0 ]
then
	# default value when platform is GPU and no --ocr flag specified
    echo "default OCR 5 GPU for dgpu devices"
	OCR_DEVICE=GPU
	OCR_INTERVAL=5
fi

echo "Device:"
echo $TARGET_GPU_DEVICE
