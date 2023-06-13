#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

source benchmark-scripts/get-gpu-info.sh
# WORKLOAD_SCRIPT is env varilable will be overwritten by --workload input option
WORKLOAD_SCRIPT="docker-run-dlstreamer.sh"

if [ -z "$PLATFORM" ] || [ -z "$INPUTSRC" ]
then
	source get-options.sh "$@"
fi

echo "running $WORKLOAD_SCRIPT"
./$WORKLOAD_SCRIPT "$@"
