from Publisher import Publisher
from KafkaCore import KafkaCore

class KafkaPublisher(Publisher):
    def push(self, height, width, depth, timestamp):
        message = {}
        message['height'] = height
        message['width'] = width
        message['timestamp'] = timestamp
        message['depth'] = depth
        KafkaCore.produce_message(message)
        

        