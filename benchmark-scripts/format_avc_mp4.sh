#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
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

WIDTH=1920
HEIGHT=1080
FPS=15

if [ -z "$2" ]
then
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

if ! [[ "$WIDTH" =~ ^[0-9]+$ ]]
then
	echo "ERROR: width should be integer."
	exit 1
fi

if ! [[ "$HEIGHT" =~ ^[0-9]+$ ]]
then
	echo "ERROR: height should be integer."
	exit 1
fi

if ! [[ "$FPS" =~ ^[0-9]+(\.[0-9]+)*$ ]]
then
	echo "ERROR: FPS should be number."
	exit 1
fi

result=${1/.mp4/"-$WIDTH-$FPS-bench.mp4"}
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


echo "$WIDTH $HEIGHT $FPS"
SAMPLE_MEDIA_DIR="$PWD"/../sample-media
docker run --network host --privileged --user root --ipc=host -e VIDEO_FILE="$1" -e DISPLAY=:0 \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-v "$SAMPLE_MEDIA_DIR"/:/vids \
	-w /vids -it  --rm intel/dlstreamer:2023.0.0-ubuntu22-gpu682-dpcpp \
	bash -c "if [ -f /vids/$result ]; then exit 1; else gst-launch-1.0 filesrc location=/vids/$1 ! qtdemux ! h264parse ! vaapih264dec ! vaapipostproc width=$WIDTH height=$HEIGHT ! videorate ! 'video/x-raw, framerate=$FPS/1' ! vaapih264enc ! h264parse ! mp4mux ! filesink location=/vids/$result; fi"

rm ../sample-media/"$1"
echo "Result will be created in ../sample-media/$result"