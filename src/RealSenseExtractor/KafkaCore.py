import json
from confluent_kafka import Producer

class KafkaCore():
    def __init__(self):
        with open('KafkaConfig.json', 'r') as config_file:
            config = json.load(config_file)
        conf = config['kafka']
        topic = conf['topic']
        producer = Producer({
            'bootstrap.servers': conf['bootstrap.servers'],
            'client.id': conf['client.id']
        })


    def delivery_report(self, err, msg):
        if err is not None:
            print(f"Message delivery failed: {err}")
        else:
            print(f"Message delivered to {msg.topic()} [{msg.partition()}]")



    def produceMessage(self, message):
        self.producer.produce(self.topic, value=message, callback=self.delivery_report)
        self.producer.poll(1)
