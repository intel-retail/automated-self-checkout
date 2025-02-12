# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#


import logging
import os
import signal
import time
import numpy as np
from datetime import datetime

from config.publisher import create_publishers
# IMPORTANT: Use the weight config function here
from config.config import read_weight_config, setup_logging


class WeightSensor:
    """
    Example Weight sensor class. Replace with real driver calls as needed.
    """
    def __init__(self, sensor_id, port, mock=False):
        self.sensor_id = sensor_id
        self.port = port
        self.mock = mock

        if not self.mock:
            # Initialize the real weight sensor (e.g., connect to the device)
            logging.info(f"Initialized real weight sensor '{self.sensor_id}' on port {self.port}")
            # TODO: Add real sensor initialization code here
        else:
            logging.info(f"Initialized mock weight sensor '{self.sensor_id}'")

    def get_readings(self):
        """
        Returns the sensor reading. If mock=True, generate random data.
        Otherwise, read from the real sensor.
        """
        if self.mock:
            # Example: random weight in kilograms
            weight_kg = np.random.uniform(0.0, 100.0)
            return weight_kg
        else:
            # Replace with actual sensor reading logic
            # Example: read from serial port, I2C, etc.
            # TODO: Add code to read data from the real sensor
            return 0.0  # Fallback placeholder

    def stop(self):
        if not self.mock:
            # Shutdown procedures for the real sensor
            logging.info(f"Stopped real weight sensor '{self.sensor_id}'")
            # TODO: Add real sensor shutdown code here
        else:
            logging.info(f"Stopped mock weight sensor '{self.sensor_id}'")


def main():
    """
    Main entry point: 
      1. Read configuration & set up logging
      2. Initialize publishers (MQTT/HTTP/Kafka, etc.)
      3. Initialize weight sensors (real or mock)
      4. Periodically read from each sensor and publish results
      5. Cleanly handle shutdown signals (SIGINT, SIGTERM)
    """
    # 1. Read config & set up logging
    config = read_weight_config()  # use the WEIGHT config function
    setup_logging(config)
    
    # 2. Create publishers (MQTT, HTTP, Kafka, etc.) based on config
    publishers = create_publishers(config["publishers"])
    
    # 3. Create weight sensor objects (based on config["weight_sensors"])
    sensors = []
    for sensor_cfg in config["weight_sensors"]:
        sensor = WeightSensor(
            sensor_id=sensor_cfg["id"],
            port=sensor_cfg["port"],
            mock=sensor_cfg["mock"]
        )
        sensors.append(sensor)
    
    # Handle graceful shutdown via signals
    shutdown = False
    def signal_handler(sig, frame):
        nonlocal shutdown
        logging.info("Shutting down gracefully...")
        shutdown = True
        
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # 4. Main loop
    publish_interval = config["global"].get("publish_interval", 1.0)
    while not shutdown:
        try:
            # Collect data from all sensors
            sensors_data = []
            timestamp = datetime.utcnow().isoformat() + "Z"
            
            # Keep track of how many sensors we have
            no_of_sensors = len(sensors)
            
            for sensor in sensors:
                weight_kg = sensor.get_readings()
                sensor_data = {
                    "sensor_id": sensor.sensor_id,
                    "weight_kg": weight_kg,
                }
                sensors_data.append(sensor_data)
            
            # Create a single payload containing data from all sensors
            payload = {
                "timestamp": timestamp,
                "sensor_count": no_of_sensors,
                "sensors": sensors_data
            }
            
            # Publish the combined payload
            for publisher in publishers:
                publisher.publish(payload)
            
            time.sleep(publish_interval)
        except Exception as e:
            logging.error(f"Error in main loop: {str(e)}")
            if os.getenv("FAIL_FAST", "false").lower() == "true":
                raise e

    # 5. Cleanup on shutdown
    for sensor in sensors:
        sensor.stop()


if __name__ == "__main__":
    main()
