#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

host=$1

curl 'localhost:8080/pipelines/detection/yolov5' --header 'Content-Type: application/json' --data '{"source": {"uri": "rtsp://'$host':8554/camera_0","type": "uri"},"destination": {"metadata": {"type": "mqtt","host": "mqtt-broker:1883","topic": "AnalyticsData0","timeout": 1000}},"parameters": {"detection-device": "CPU"}}'
curl 'localhost:8081/pipelines/detection/yolov5' --header 'Content-Type: application/json' --data '{"source": {"uri": "rtsp://'$host':8554/camera_0","type": "uri"},"destination": {"metadata": {"type": "mqtt","host": "mqtt-broker:1883","topic": "AnalyticsData1","timeout": 1000}},"parameters": {"detection-device": "CPU"}}'
curl 'localhost:8082/pipelines/detection/yolov5' --header 'Content-Type: application/json' --data '{"source": {"uri": "rtsp://'$host':8554/camera_0","type": "uri"},"destination": {"metadata": {"type": "mqtt","host": "mqtt-broker:1883","topic": "AnalyticsData2","timeout": 1000}},"parameters": {"detection-device": "CPU"}}'
