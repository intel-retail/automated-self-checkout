#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "Starting telegraf service"

INFLUX_TOKEN=$(docker exec influxdb2 influx auth list --user telegraf --json | grep token | cut -d : -f 2 | cut -d \" -f 2)

docker run  -itd --privileged --network host --env telegraf_hostname="intel-telegraf" --env influx_url="http://127.0.0.1:8086" --env influx_db="influxdb" --env INFLUX_TOKEN="$INFLUX_TOKEN" --name telegraf intel-telegraf:1.0

