#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

REFRESH_INPUT=
OPEN_OVMS=0

show_help() {
    echo "
        usage: $0
            --workload dlstreamer|opencv-ovms
            --refresh 
        Note:
            --refresh is optional, it removes previously downloaded model files
    "
}

get_options() {
    while :; do
        case $1 in
            -h | -\? | --help)
                show_help
                exit 0
            ;;
            --refresh)
                echo "running model downloader in refresh mode"
                REFRESH_INPUT="--refresh"
                ;;
            --workload)
                echo "workload: ${2}"
                if [ "$2" == "opencv-ovms" ]; then
                    OPEN_OVMS=1
                else 
                    if [ "$2" != "dlstreamer" ]; then
                        echo 'ERROR: "--workload" requires an argument dlstreamer|opencv-ovms'
                        exit 1
                    fi
                fi
                shift
                ;;
            *)
                break
                ;;
            esac
            shift
        done

}

if [ -z $1 ]
then
    show_help
fi

get_options "$@"

if [ "$OPEN_OVMS" -eq 1 ]; then
    echo "Starting open-ovms model download..."
    ./downloadOVMSModels.sh $REFRESH_INPUT
else
    echo "Starting dlstreamer model download..."
    ./modelDownload.sh $REFRESH_INPUT
fi
