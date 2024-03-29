#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# tqdm needed?
pip install -q "torch>=2.1" "torchvision>=0.16" "ultralytics==8.0.43" onnx --extra-index-url https://download.pytorch.org/whl/cpu
pip install nncf>=2.5.0

