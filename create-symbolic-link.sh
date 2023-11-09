#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

TARGET_LINK="$1"
SOURCE_LINK="$2"

if [ -e "$SOURCE_LINK" ];
then
    echo "symbolic link $SOURCE_LINK existing, remove it..."
    sudo unlink "$SOURCE_LINK"
fi

ln -s "$TARGET_LINK" "$SOURCE_LINK"
