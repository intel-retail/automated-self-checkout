#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

CARDS=$(/usr/local/bin/intel_gpu_top -L | grep card1)

if [ "$CARDS" != "" ]; then
    #iGPU
    JSON=$(/usr/bin/timeout -k 2 2 /usr/local/bin/intel_gpu_top -J -d pci:card=1)    
    RENDER_UTIL=$(echo "$JSON"|grep Render/3D/0 -A 1|tail -1|grep busy|cut -d ":" -f2|cut -d "," -f1|cut -d " " -f2)
    #dgpu
    JSON2=$(/usr/bin/timeout -k 2 2 /usr/local/bin/intel_gpu_top -J -d pci:card=0)    
    RENDER_UTIL2=$(echo "$JSON2"|grep unknown\]/0 -A 1|tail -1|grep busy|cut -d ":" -f2|cut -d "," -f1|cut -d " " -f2)
    echo "[{\"time\": `date +%s`, \"iGPU Compute Util\": "$RENDER_UTIL", \"dGPU Arc Compute Util\": "$RENDER_UTIL2"}]"
else
    #iGPU only
    JSON=$(/usr/bin/timeout -k 2 2 /usr/local/bin/intel_gpu_top -J -d pci:card=0)    
    RENDER_UTIL=$(echo "$JSON"|grep Render/3D/0 -A 1|tail -1|grep busy|cut -d ":" -f2|cut -d "," -f1|cut -d " " -f2)
    echo "[{\"time\": `date +%s`, \"iGPU Compute Util\": "$RENDER_UTIL"}]"
fi
exit 0