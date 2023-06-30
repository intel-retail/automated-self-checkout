#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# the results of docker ps -aq is meant to be re-splitting in order for the docker rm to be working
# shellcheck disable=SC2046
docker rm -f $(docker ps -aq)
