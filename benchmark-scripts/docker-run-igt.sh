#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

SOURCE_DIR=$(dirname "$(readlink -f "$0")")
if [ -z $1 ]; then
	echo "PCI card id required"
else
	docker run -v `pwd`/results:/tmp/results -itd --privileged igt:latest bash -c "/usr/local/bin/intel_gpu_top -d pci:card=$1 -J > /tmp/results/igt$1.json"
	#docker run -v $SOURCE_DIR/results:/tmp/results -it --privileged igt:latest bash -c "/usr/local/bin/intel_gpu_top -d pci:card=$1"
fi
