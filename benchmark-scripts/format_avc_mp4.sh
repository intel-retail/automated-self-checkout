#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

show_help() {
        echo "
         usage: $0 video_name.mp4 URL_TO_MP4 [width height fps]

         Note:
          1. This utility will convert the video_name.mp4 file to 4k@15FPS in AVC and requires Intel GPU.
	  2. The video_name.mp4 file must reside in the sample-media folder.
	  3. The video_name.mp4 file must already be in AVC format.
        "
}

WIDTH=3840
HEIGHT=2160
FPS=15
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
        #echo "GPU exists!"
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

        #echo "HAS_FLEX_140=$HAS_FLEX_140, HAS_FLEX_170=$HAS_FLEX_170, HAS_ARC=$HAS_ARC"
}


get_gpu_devices

if [ -z "$2" ]
then
        show_help
        exit 1
fi


result=${1/.mp4/"-bench.mp4"}
if [ -f ../sample-media/$result ]
then
	echo "Skipping...conversion was already done for ../sample-media/$result."
	exit 0
fi

if [ ! -f ../sample-media/$1 ] && [ ! -f ../sample-media/$result ]
then	
	wget -O ../sample-media/$1 $2
fi

if [ ! -f ../sample-media/$1 ]
then
	echo "ERROR: Can not find video file or 
	"
	show_help
	exit 1
fi

if [ ! -z "$3" ]
then
	WIDTH=$3
fi

if [ ! -z "$4" ]
then
        HEIGHT=$4
fi

if [ ! -z "$5" ]
then
        FPS=$5
fi

if [ -z "$WIDTH" ] || [ -z "$HEIGHT" ] || [ -z "$FPS" ]
then
	echo "ERROR: Invalid width height fps"
	exit 1
fi


if [ $HAS_FLEX_140 == 1 ] || [ $HAS_FLEX_170 == 1 ] || [ $HAS_ARC == 1 ]
then
        TAG=sco-dgpu:2.0

else
        echo "ERROR: Requires Intel Flex/Arc GPU"
	exit 1
fi

echo "$WIDTH $HEIGHT $FPS"
docker run --network host --privileged --user root --ipc=host -e VIDEO_FILE=$1 -e DISPLAY=:0 -v /tmp/.X11-unix:/tmp/.X11-unix -v `pwd`/../sample-media/:/vids -w /vids -it  --rm $TAG bash -c "if [ -f /vids/$result ]; then exit 1; else gst-launch-1.0 filesrc location=/vids/$1 ! qtdemux ! h264parse ! vaapih264dec ! vaapipostproc width=$WIDTH height=$HEIGHT ! videorate ! 'video/x-raw, framerate=$FPS/1' ! vaapih264enc ! h264parse ! mp4mux ! filesink location=/vids/$result; fi"

rm ../sample-media/$1
echo "Result will be created in ../sample-media/$result"
