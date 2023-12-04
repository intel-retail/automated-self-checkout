#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

REFRESH_INPUT=

show_help() {
    echo "
        usage: $0
            --refresh 
        Note:
            1. --refresh is optional, it removes previously downloaded model files
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
            *)
                break
                ;;
            esac
            shift
        done

}

get_options "$@"

MODEL_EXEC_PATH="$(dirname "$(readlink -f "$0")")"
echo "model execution path: $MODEL_EXEC_PATH"
echo "Starting open-ovms model download..."
"$MODEL_EXEC_PATH"/downloadOVMSModels.sh $REFRESH_INPUT
