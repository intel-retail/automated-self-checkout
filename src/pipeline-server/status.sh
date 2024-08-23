#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

while true
do
    echo "--------------------- Pipeline Status ---------------------" >> status_results.txt
    echo "----------------8080----------------" >> status_results.txt
    curl --location 'localhost:8080/pipelines/status' >> status_results.txt
    echo "----------------8081----------------" >> status_results.txt
    curl --location 'localhost:8071/pipelines/status' >> status_results.txt
    echo "----------------8082----------------" >> status_results.txt
    curl --location 'localhost:8072/pipelines/status' >> status_results.txt
    sleep 15
done
