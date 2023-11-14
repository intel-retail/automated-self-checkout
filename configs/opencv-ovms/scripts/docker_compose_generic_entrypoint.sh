#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "Waiting for OVMS server to be ready...."
sleep 10
echo "Done Waiting...."

echo "ENTRYPOINT_SCRIPT: "
echo "$ENTRYPOINT_SCRIPT"
source "$ENTRYPOINT_SCRIPT"
