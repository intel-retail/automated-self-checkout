#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

FROM intel/dlstreamer:2023.0.0-ubuntu22-gpu682-dpcpp as base
USER root

RUN apt-get update && apt-get install --no-install-recommends -y wget

COPY src/requirements.txt /requirements.txt
RUN pip3 install --upgrade pip --no-cache-dir -r /requirements.txt
WORKDIR /
COPY src/extensions /home/pipeline-server/extensions
COPY src/pipelines /home/pipeline-server/pipelines

RUN mkdir -p /home/pipeline-server/models/yolov5s/FP16-INT8/1
RUN mkdir -p /home/pipeline-server/models/efficientnet-b0/FP32-INT8/1
RUN wget https://github.com/dlstreamer/pipeline-zoo-models/tree/main/storage/yolov5s-416_INT8/yolo-v5.json -P /home/pipeline-server/models/yolov5s/FP16-INT8/1/yolov5s.json && \
    wget https://github.com/dlstreamer/pipeline-zoo-models/tree/main/storage/yolov5s-416_INT8/FP16-INT8/yolov5s.xml -P /home/pipeline-server/models/yolov5s/FP16-INT8/1/yolov5s.xml && \
    wget https://github.com/dlstreamer/pipeline-zoo-models/tree/main/storage/yolov5s-416_INT8/FP16-INT8/yolov5s.bin -P /home/pipeline-server/models/yolov5s/FP16-INT8/1/yolov5s.bin
RUN wget https://github.com/dlstreamer/pipeline-zoo-models/tree/main/storage/efficientnet-b0_INT8/efficientnet-b0.json -P /home/pipeline-server/models/efficientnet-b0/efficientnet-b0.json && \
    wget https://github.com/dlstreamer/pipeline-zoo-models/tree/main/storage/efficientnet-b0_INT8/FP16-INT8/efficientnet-b0.xml -P /home/pipeline-server/models/efficientnet-b0/FP32-INT8/1/efficientnet-b0.xml && \
    wget https://github.com/dlstreamer/pipeline-zoo-models/tree/main/storage/efficientnet-b0_INT8/FP16-INT8/efficientnet-b0.bin -P /home/pipeline-server/models/efficientnet-b0/FP32-INT8/1/efficientnet-b0.bin && \
    wget https://raw.githubusercontent.com/dlstreamer/dlstreamer/master/samples/labels/imagenet_2012.txt -P /home/pipeline-server/models/efficientnet-b0/imagenet_2012.txt

COPY src/entrypoint.sh /script/entrypoint.sh
RUN mkdir /tmp/results