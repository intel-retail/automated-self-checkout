#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0

echo "start download from list models.lst"
omz_downloader --list models.lst
omz_converter --list models.lst
cp -r intel/* /2022/