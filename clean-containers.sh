#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

mapfile -t containers < <(docker ps  --filter="name=$1" -q -a)
if [ "${#containers[@]}" -eq 0 ];
then
        echo "nothing to clean up"
else
    for sid in "${containers[@]}"
    do
        echo "cleaning up dangling container"
        docker rm $sid -f
    done
fi