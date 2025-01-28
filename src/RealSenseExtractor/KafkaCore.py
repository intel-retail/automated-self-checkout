import json
from confluent_kafka import Producer

class KafkaCore():
    def __init__(self):
        with open('RealSenseConfig.json', 'r') as config_file:
            config = json.load(config_file)
        conf = config['kafka']
        self.topic = conf['topic']
        self.producer = Producer({
            'bootstrap.servers': conf['bootstrap.servers'],
            'client.id': conf['client.id']
        })


    def delivery_report(self, err, msg):
        if err is not None:
            print(f"Message delivery failed: {err}")
        else:
            print(f"Message delivered to {msg.topic()} [{msg.partition()}]")



    def produce_message(self, message):
        byte_message = json.dumps(message).encode('utf-8')
        self.producer.produce(self.topic, value=byte_message, callback=self.delivery_report)
        self.producer.poll(1)
