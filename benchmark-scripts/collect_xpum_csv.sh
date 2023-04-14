#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Measure temp, frequency , power usage
echo "Collecting Flex metrics in $1/flex-metrics.csv"
xpumcli dump -m 0,1,2,3,8 > $1/flex-metrics.csv

