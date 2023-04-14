#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

echo "stopping platform data collection..."
sudo pkill -f iotop
sudo pkill -f free
sudo pkill -f sar
sudo pkill -f pcm-power
sudo pkill -f pcm
sudo pkill -f xpumcli
sudo pkill -f intel_gpu_top
sudo pkill -f pcm-memory
sleep 2
