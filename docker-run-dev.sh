#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

error() {
    printf '%s\n' "$1" >&2
    exit
}

show_help() {
	echo "
         usage: ./docker-run.sh --platform core|xeon|dgpu.x --inputsrc RS_SERIAL_NUMBER|CAMERA_RTSP_URL|file:video.mp4|/dev/video0 [--classification_disabled] [ --ocr_disabled | --ocr [OCR_INTERVAL OCR_DEVICE] ] [ --barcode_disabled | --barcode [BARCODE_INTERVAL] ]

         Note: 
	  1. dgpu.x should be replaced with targetted GPUs such as dgpu (for all GPUs), dgpu.0, dgpu.1, etc
	  2. filesrc will utilize videos stored in the sample-media folder
        "
}

HAS_FLEX_140=0
HAS_FLEX_170=0
HAS_ARC=0
#HAS_iGPU=0

get_gpu_devices() {
	has_gpu=0
	has_any_intel_non_server_gpu=`dmesg | grep -i "class 0x030000" | grep "8086"`
	has_any_intel_server_gpu=`dmesg | grep -i "class 0x038000" | grep "8086"`
	has_flex_170=`echo "$has_any_intel_server_gpu" | grep -i "56C0"`
	has_flex_140=`echo "$has_any_intel_server_gpu" | grep -i "56C1"`
	has_arc=`echo "$has_any_intel_non_server_gpu" | grep -iE "5690|5691|5692|56A0|56A1|56A2|5693|5694|5695|5698|56A5|56A6|56B0|56B1|5696|5697|56A3|56A4|56B2|56B3"`

	if [ -z "$has_any_intel_non_server_gpu" ] && [ -z "$has_any_intel_server_gpu" ] 
	then
		echo "No Intel GPUs found"
		return
	fi
	echo "GPU exists!"

	if [ ! -z "$has_flex_140" ]
	then
		HAS_FLEX_140=1
	fi
	if [ ! -z "$has_flex_170" ]
        then
                HAS_FLEX_170=1
	fi
        if [ ! -z "$has_arc" ]
        then
                HAS_ARC=1
	fi

	echo "HAS_FLEX_140=$HAS_FLEX_140, HAS_FLEX_170=$HAS_FLEX_170, HAS_ARC=$HAS_ARC"
}

get_options() {
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
			TARGET_GPU_DEVICE="--device=/dev/dri/renderD128"
			shift
		elif grep -q "dgpu" <<< "$2"; then			
			arrgpu=(${2//./ })
		        gpu_number=${arrgpu[1]}
			if [ -z "$gpu_number" ]; then
				TARGET_GPU="GPU.0"
				TARGET_GPU_DEVICE="--privileged"
			else
				gid=$((128+$gpu_number))

				TARGET_GPU="GPU."$gpu_number
				TARGET_GPU_DEVICE="--device=/dev/dri/renderD"$gid
			fi
			PLATFORM="dgpu"
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
            ;;
        --barcode)
            if [ "$2" ]; then
                BARCODE_INTERVAL=$2
            else
                error 'ERROR: "--barcode" requires an argument [BARCODE_INTERVAL].'
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
}

BARCODE_DISABLED=0
BARCODE_INTERVAL=5
OCR_INTERVAL=5
OCR_DEVICE=CPU
OCR_DISABLED=0
CLASSIFICATION_DISABLED=0
export GST_DEBUG=0

get_options "$@"
get_gpu_devices

if [ -z $1 ] || [ -z $PLATFORM ] || [ -z $INPUTSRC ]
then
        show_help
	exit 0
fi

cl_cache_dir=`pwd`/.cl-cache
echo "CLCACHE: $cl_cache_dir"

#HAS_FLEX_140=$HAS_FLEX_140, HAS_FLEX_170=$HAS_FLEX_170, HAS_ARC=$HAS_ARC


if [ $HAS_FLEX_140 == 1 ] || [ $HAS_FLEX_170 == 1 ] || [ $HAS_ARC == 1 ] 
then
	echo "Arc/Flex device support"
	TAG=sco-dgpu:2.0

else
	echo "SOC (CPU, iGPU, and Xeon SP) device support"
	TAG=sco-soc:2.0
fi

cids=$(docker ps  --filter="name=vision-self-checkout" -q -a)
cid_count=`echo "$cids" | wc -w`
CONTAINER_NAME="vision-self-checkout"$(($cid_count))
LOG_FILE_NAME="vision-self-checkout"$(($cid_count))".log"

#echo "barcode_disabled: $BARCODE_DISABLED, barcode_interval: $BARCODE_INTERVAL, ocr_interval: $OCR_INTERVAL, ocr_device: $OCR_DEVICE, ocr_disabled=$OCR_DISABLED, class_disabled=$CLASSIFICATION_DIABLED"

if grep -q "rtsp" <<< "$INPUTSRC"; then
	# rtsp
	# todo pass depay info
	inputsrc=$INPUTSRC" ! rtph264depay "
	INPUTSRC_TYPE="RTSP"
	pre_process="pre-process-backend=vaapi-surface-sharing -e pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1"

elif grep -q "file" <<< "$INPUTSRC"; then
	# filesrc	
	arrfilesrc=(${INPUTSRC//:/ })
	# use vids since container maps a volume to this location based on sample-media folder
	# TODO: need to pass demux/codec info
	inputsrc="filesrc location=vids/"${arrfilesrc[1]}" ! qtdemux ! h264parse "
	INPUTSRC_TYPE="FILE"

elif grep -q "video" <<< "$INPUTSRC"; then
	# v4l2src /dev/video*
	# TODO need to pass stream info
	inputsrc="v4l2src device="$INPUTSRC
	INPUTSRC_TYPE="USB"

else
	# rs-serial realsenssrc
	# TODO need to pass depthalign info
	cameras=`ls /dev/vid* | while read line; do echo "--device=$line"; done`
	TARGET_GPU_DEVICE=$TARGET_GPU_DEVICE" "$cameras
	inputsrc="realsensesrc cam-serial-number="$INPUTSRC" stream-type=0 align=0 imu_on=false"
	INPUTSRC_TYPE="REALSENSE"
fi

if [ "${OCR_DISABLED}" == "0" ] && [ "${BARCODE_DISABLED}" == "0" ] && [ "${CLASSIFICATION_DISABLED}" == "0" ]; then
	pipeline="yolov5s_full.sh"
	
elif [ "${OCR_DISABLED}" == "1" ] && [ "${BARCODE_DISABLED}" == "1" ] && [ "${CLASSIFICATION_DISABLED}" == "1" ]; then
	pipeline="yolov5s.sh"
elif [ "${OCR_DISABLED}" == "1" ] && [ "${BARCODE_DISABLED}" == "1" ] && [ "${CLASSIFICATION_DISABLED}" == "0" ]; then
        pipeline="yolov5s_effnetb0.sh"
else
	echo "Not implemented"
	exit 0
fi

docker run --network host $TARGET_GPU_DEVICE --user root --ipc=host --name vision-self-checkout$cid_count -v `pwd`/configs/framework-pipelines/stream_density.sh:/home/pipeline-server/stream_density_framework-pipelines.sh -e INPUTSRC_TYPE=$INPUTSRC_TYPE -e DISPLAY=:0 -e cl_cache_dir=/home/pipeline-server/.cl-cache -v $cl_cache_dir:/home/pipeline-server/.cl-cache -v /tmp/.X11-unix:/tmp/.X11-unix -v `pwd`/sample-media/:/home/pipeline-server/vids -v `pwd`/configs/pipelines:/home/pipeline-server/pipelines -v `pwd`/configs/extensions:/home/pipeline-server/extensions -v `pwd`/results:/tmp/results -v `pwd`/configs/models/2022:/home/pipeline-server/models -v `pwd`/configs/framework-pipelines:/home/pipeline-server/framework-pipelines -w /home/pipeline-server -e BARCODE_RECLASSIFY_INTERVAL=$BARCODE_INTERVAL -e OCR_RECLASSIFY_INTERVAL=$OCR_INTERVAL -e OCR_DEVICE=$OCR_DEVICE -e LOG_LEVEL=$LOG_LEVEL -e GST_DEBUG=$GST_DEBUG -e cid_count=$cid_count -e pre_process="$pre_process" -e LOW_POWER="$LOW_POWER" -e CPU_ONLY="$CPU_ONLY" -e inputsrc="$inputsrc" --rm -it $TAG 
