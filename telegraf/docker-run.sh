#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

./docker-run-influxdb.sh
sleep 5
#docker exec influxdb2 influx auth create --all-access --org telegraf
sleep 5
./docker-run-telegraf.sh
