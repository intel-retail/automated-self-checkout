# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

import os
import time
import json
import logging
from datetime import datetime
import paho.mqtt.client as mqtt

###############################################################################
# 1. Configuration & Logging Setup
###############################################################################

def setup_logging():
    """
    Sets up Python logging with the desired log level.
    """
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    logging.info("Logging is configured.")

###############################################################################
# 2. MQTT Setup
###############################################################################

MQTT_BROKER_HOST = os.getenv("MQTT_BROKER_HOST", "localhost")
MQTT_BROKER_PORT = int(os.getenv("MQTT_BROKER_PORT", "1883"))
LIDAR_TOPIC = "lidar/data"
WEIGHT_TOPIC = "weight/data"
ANALYTICS_TOPIC = "analytics/data"

# Store data for analytics
lidar_data = []
weight_data = []

###############################################################################
# 3. MQTT Callbacks
###############################################################################

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        logging.info("Connected to MQTT Broker.")
        client.subscribe(LIDAR_TOPIC)
        client.subscribe(WEIGHT_TOPIC)
    else:
        logging.error(f"Failed to connect, return code {rc}")

def on_message(client, userdata, msg):
    global lidar_data, weight_data

    try:
        payload = json.loads(msg.payload.decode("utf-8"))

        if msg.topic == LIDAR_TOPIC:
            lidar_data.append(payload)
            logging.info(f"Received LiDAR data: {payload}")
        elif msg.topic == WEIGHT_TOPIC:
            weight_data.append(payload)
            logging.info(f"Received Weight data: {payload}")

        # Perform analytics once data from both sensors is available
        if lidar_data and weight_data:
            publish_analytics(client)

    except Exception as e:
        logging.error(f"Error processing message: {e}")

###############################################################################
# 4. Analytics Function
###############################################################################

def publish_analytics(client):
    global lidar_data, weight_data

    try:
        # Extract relevant information from the latest data
        latest_lidar = lidar_data.pop(0)
        latest_weight = weight_data.pop(0)

        # Example analytics: Calculate item density based on weight and area from LiDAR
        total_weight = latest_weight.get("weight", 0)  # In kilograms
        num_points = len(latest_lidar.get("readings", []))

        # Density: weight per LiDAR point (example metric)
        density = total_weight / num_points if num_points > 0 else 0

        # Prepare analytics payload
        analytics_payload = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "total_weight": total_weight,
            "num_points": num_points,
            "density": round(density, 2),
        }

        # Publish analytics
        client.publish(ANALYTICS_TOPIC, json.dumps(analytics_payload), qos=1)
        logging.info(f"Published analytics: {analytics_payload}")

    except Exception as e:
        logging.error(f"Error in analytics calculation: {e}")

###############################################################################
# 5. Main Function
###############################################################################

def main():
    setup_logging()

    # Initialize MQTT client
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    try:
        logging.info("Connecting to MQTT broker...")
        client.connect(MQTT_BROKER_HOST, MQTT_BROKER_PORT, keepalive=60)
        client.loop_forever()
    except Exception as e:
        logging.error(f"Failed to connect or maintain MQTT loop: {e}")

###############################################################################
# 6. Entry Point
###############################################################################

if __name__ == "__main__":
    main()