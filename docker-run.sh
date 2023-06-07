#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# clean up exited containers
docker rm $(docker ps -a -f name=automated-self-checkout -f status=exited -q)

source benchmark-scripts/get-gpu-info.sh

if [ -z "$PLATFORM" ] || [ -z "$INPUTSRC" ]
then
	source get-options.sh "$@"
fi

#todo figure out how to have the workload script see the env variables set by get-options.sh so that it doesn't have to be run twice. 
# or modify this script to determine the workload script
echo "running $WORKLOAD_SCRIPT"
./$WORKLOAD_SCRIPT "$@"
