# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#


import json
import time
import logging
import argparse
from kafka import KafkaConsumer

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# Argument Parser
parser = argparse.ArgumentParser(description="Kafka Consumer Test")
parser.add_argument("--topic", type=str, required=True, help="Kafka topic to subscribe to")
parser.add_argument("--server", type=str, default="kafka:9093", help="Kafka bootstrap server address")
parser.add_argument("--timeout", type=int, default=10, help="Timeout in seconds for consuming messages")
args = parser.parse_args()

def test_kafka_consumer(topic, kafka_server, timeout_seconds):
    """Test Kafka consumer by listening to a user-specified topic."""
    
    logging.info(f"🚀 Listening for messages on topic: {topic}")
    
    try:
        consumer = KafkaConsumer(
            topic,
            bootstrap_servers=kafka_server,
            auto_offset_reset="earliest",  # Start from the beginning of the topic
            enable_auto_commit=True,
            group_id=f"test-group-{topic}",
            consumer_timeout_ms=timeout_seconds * 1000  # Convert to milliseconds
        )

        # Attempt to read messages
        for message in consumer:
            msg_data = json.loads(message.value.decode("utf-8"))
            logging.info(f"✅ Received message from {topic}: {msg_data}")
            return True  # Test passed

        logging.warning(f"⚠️ No messages received on {topic} within the timeout period.")
        return False  # Test failed (no messages received)

    except Exception as e:
        logging.error(f"❌ Error in Kafka Consumer for {topic}: {e}")
        return False

# Run test
if __name__ == "__main__":
    result = test_kafka_consumer(args.topic, args.server, args.timeout)
    if result:
        logging.info(f"✅ Kafka Consumer Test Passed for topic '{args.topic}'!")
    else:
        logging.error(f"❌ Kafka Consumer Test Failed for topic '{args.topic}'!")
