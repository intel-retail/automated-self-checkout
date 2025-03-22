#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

FROM intel/dlstreamer:2024.1.1-dev-ubuntu22 as base
USER root

COPY helm/requirements.txt /requirements.txt
RUN pip3 install --upgrade pip --no-cache-dir -r /requirements.txt
WORKDIR /
COPY src/extensions /home/pipeline-server/extensions
COPY src/pipelines /home/pipeline-server/pipelines
COPY /download_models/downloadModels.sh /home/pipeline-server/models/downloadModels.sh
WORKDIR /home/pipeline-server/models
RUN sh downloadModels.sh
WORKDIR /

COPY src/entrypoint.sh /script/entrypoint.sh
RUN mkdir /tmp/results