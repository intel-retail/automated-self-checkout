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

source ../get-gpu-info.sh

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