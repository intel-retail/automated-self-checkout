#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

./docker-run-influxdb.sh
sleep 10
./docker-run-telegraf.sh
