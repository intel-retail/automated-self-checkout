from Publisher import Publisher
from KafkaCore import produceMessage

class KafkaPublisher(Publisher):
    def push(self, height, width, depth, timestamp):
        message = {}
        message['height'] = height
        message['width'] = width
        message['timestamp'] = timestamp
        message['depth'] = depth
        produceMessage(message)
        

        