#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

FROM intel/dlstreamer:2024.1.1-dev-ubuntu22
USER root

# Add proxy environment variables
ENV NO_PROXY="localhost,127.0.0.1,.intel.com,10.0.0.0/8,192.168.0.0/16"

COPY helm/requirements.txt /requirements.txt
RUN pip3 install --upgrade pip --no-cache-dir -r /requirements.txt
WORKDIR /
COPY src/extensions /home/pipeline-server/extensions
COPY src/pipelines /home/pipeline-server/pipelines
COPY /download_models/downloadModels.sh /home/pipeline-server/models/downloadModels.sh
#
WORKDIR /

COPY src/entrypoint.sh /script/entrypoint.sh
RUN mkdir /tmp/results

RUN mkdir -p /mnt/rtsp-media && \
    wget --verbose --tries=3 --timeout=30 -O /mnt/rtsp-media/obj_classification-1920-15-bench.mp4 https://www.pexels.com/download/video/4465029
