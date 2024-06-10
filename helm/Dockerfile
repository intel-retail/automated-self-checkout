#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

#FROM intel/dlstreamer:2022.2.0-ubuntu20-gpu815 as base
FROM intel/dlstreamer:2023.0.0-ubuntu22-gpu682-dpcpp as base
USER root

COPY src/requirements.txt /requirements.txt
RUN pip3 install --upgrade pip --no-cache-dir -r /requirements.txt
WORKDIR /
COPY src/extensions /home/pipeline-server/extensions
COPY src/pipelines /home/pipeline-server/framework-pipelines
RUN mkdir -p /home/pipeline-server/models/yolov5s/FP16-INT8/1
RUN wget -O /home/pipeline-server/models/yolov5s/FP16-INT8/1/yolo-v5.json https://github.com/dlstreamer/pipeline-zoo-models/blob/main/storage/yolov5s-416_INT8/yolo-v5.json
RUN wget -O /home/pipeline-server/models/yolov5s/FP16-INT8/1/yolov5s.bin https://github.com/dlstreamer/pipeline-zoo-models/blob/main/storage/yolov5s-416_INT8/FP16-INT8/yolov5s.bin
RUN wget -O /home/pipeline-server/models/yolov5s/FP16-INT8/1/yolov5s.xml https://github.com/dlstreamer/pipeline-zoo-models/blob/main/storage/yolov5s-416_INT8/FP16-INT8/yolov5s.xml

COPY src/entrypoint.sh /script/entrypoint.sh
RUN mkdir /tmp/results