# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

from Publisher import Publisher
from KafkaCore import KafkaCore

class KafkaPublisher(Publisher):
    def __init__(self):
        self.kafka_core = KafkaCore()
        
    def push(self, height, width, depth, timestamp):
        message = {}
        message['height'] = height
        message['width'] = width
        message['timestamp'] = str(timestamp)
        message['depth'] = depth
        self.kafka_core.produce_message(message=message)
        

        