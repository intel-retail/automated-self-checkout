#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

docker inspect "$SERVER_CONTAINER_INSTANCE" | docker run -i --rm -v ./:/app ghcr.io/jqlang/jq -r '.[].Args[3]'
