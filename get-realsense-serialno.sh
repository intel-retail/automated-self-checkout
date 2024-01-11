#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

DLSTREAMER_REALSENSE_IMG="dlstreamer:realsense"

# first to test it in case there is no /dev/vid at all
if ! find /dev/vid* > /dev/null 2>&1;
then
    echo "no /dve/vid* found"
    # list of exit code in section of List of common exit codes for GNU/Linux https://www.cyberciti.biz/faq/linux-bash-exit-status-set-exit-statusin-bash/
    exit 6
fi

cameras=$(find /dev/vid* | while read -r line; do echo "--device=$line"; done)
# replace \n with white space as the above output contains \n
cameras=("$(echo "$cameras" | tr '\n' ' ')")

if [ -z "${cameras[*]}" ]
then
    echo "ERROR: there is no device /dev/vid found"
    exit 6
fi

docker image inspect "$DLSTREAMER_REALSENSE_IMG" >/dev/null
imgNotExists="$?"

if [ "$imgNotExists" == "1" ]
then
    echo " docker image $DLSTREAMER_REALSENSE_IMG doesn't exist, please build it first"
    exit 1
fi

# the $cameras used as command line for docker and meant to be word-splitting
# shellcheck disable=SC2086
docker run --rm --network host $cameras --user root --ipc=host --name automated-self-checkout0 -w /home/pipeline-server "$DLSTREAMER_REALSENSE_IMG" \
bash -c "rs-enumerate-devices | grep -E \"^[[:space:]]+Serial Number\" | grep -o '[0-9]\+'"
