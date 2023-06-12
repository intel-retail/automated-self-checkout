#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# the results of docker ps -aq is meant to be re-splitting in order for the docker rm to be working
# shellcheck disable=SC2046
docker rm -f $(docker ps -aq)
