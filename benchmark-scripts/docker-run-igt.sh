#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

if [ -z $1 ]; then
	echo "PCI card id required"
else
	echo $SOURCE_DIR
	docker run -v $SOURCE_DIR/results:/tmp/results -itd --privileged igt:latest bash -c "/usr/local/bin/intel_gpu_top -d pci:card=$1 -J > /tmp/results/igt$1.json"
	#docker run -v $SOURCE_DIR/results:/tmp/results -it --privileged igt:latest bash -c "/usr/local/bin/intel_gpu_top -d pci:card=$1"
fi
