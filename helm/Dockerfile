#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

FROM intel/dlstreamer:2023.0.0-ubuntu22-gpu682-dpcpp as base
USER root

COPY src/requirements.txt /requirements.txt
RUN pip3 install --upgrade pip --no-cache-dir -r /requirements.txt
WORKDIR /
COPY src/extensions /home/pipeline-server/extensions
COPY src/pipelines /home/pipeline-server/pipelines
COPY /models /home/pipeline-server/models

COPY src/entrypoint.sh /script/entrypoint.sh
RUN mkdir /tmp/results