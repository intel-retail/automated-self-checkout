#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

show_help() {
	echo " 
         usage: ./get-media-codec.sh CAMERA_RTSP_URL|file:video.mp4|/dev/video0
        "
}


if [ -z $1 ]
then	
   	show_help
	exit 0
else
    is_avc=`gst-discoverer-1.0 $1 | grep -i h.264 | wc -l`
fi