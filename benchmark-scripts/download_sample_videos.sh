#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# up to 3 bottles and human hand
./format_avc_mp4.sh coca-cola-4465029.mp4 https://www.pexels.com/video/4465029/download/ "$1" "$2" "$3"
./format_avc_mp4.sh vehicle-bike.mp4 https://www.pexels.com/video/853908/download/ "$1" "$2" "$3"
#./format_avc_mp4.sh grocery-items-on-the-kitchen-shelf-4983686.mp4 https://www.pexels.com/video/4983686/download/ $1 $2 $3
./format_avc_mp4.sh video_of_people_walking_855564.mp4 https://www.pexels.com/video/855564/download/ "$1" "$2" "$3"
./format_avc_mp4.sh barcode.mp4 https://github.com/antoniomtz/sample-clips/raw/main/barcode.mp4 "$1" "$2" "$3"
