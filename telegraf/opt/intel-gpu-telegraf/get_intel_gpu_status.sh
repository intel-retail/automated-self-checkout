#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

JSON=$(/usr/bin/timeout -k 3 3 /usr/local/bin/intel_gpu_top -J)
VIDEO_UTIL=$(echo "$JSON"|grep Render/3D/0 -A 1|tail -1|grep busy|cut -d ":" -f2|cut -d "," -f1|cut -d " " -f2)

echo "[{\"time\": `date +%s`, \"intel_gpu_util\": "$VIDEO_UTIL"}]"

exit 0