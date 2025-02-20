# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

import pyrealsense2 as rs
from datetime import datetime
from GrafanaPublisher import GrafanaPublisher
from MicroServicePublisher import MicroServicePublisher
from KafkaPublisher import KafkaPublisher

pipeline = rs.pipeline()
config = rs.config()
config.enable_stream(rs.stream.depth, rs.format.z16)
pipeline.start(config)

kafka_publisher = KafkaPublisher()
Grafana_publisher = GrafanaPublisher()
microservice_publisher = MicroServicePublisher()
    

while True:
    try:
        frames = pipeline.wait_for_frames()
        depth_frame = frames.get_depth_frame()
            
        if not depth_frame:
            raise RuntimeError("Could not get depth frame")

        width = depth_frame.get_width()
        height = depth_frame.get_height()
        time_stamp = depth_frame.get_timestamp()
        center_x, center_y = width // 2, height // 2
        depth = depth_frame.get_distance(center_x, center_y)
        
        kafka_publisher.push()
        Grafana_publisher.push()
        microservice_publisher.push()

    finally:
        pipeline.stop()
