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
from config.config import read_barcode_config, setup_logging

class BarcodeSensor:
    """
    Example Barcode sensor class. Replace with real driver calls as needed.
    """
    def __init__(self, sensor_id, port, mock=False):
        self.sensor_id = sensor_id
        self.port = port
        self.mock = mock

        if not self.mock:
            # Initialize the real barcode sensor (e.g., connect to the device)
            logging.info(f"Initialized real barcode sensor '{self.sensor_id}' on port {self.port}")
            # TODO: Add real sensor initialization code here
        else:
            logging.info(f"Initialized mock barcode sensor '{self.sensor_id}'")

    def get_readings(self):
        """
        Returns the sensor reading. If mock=True, generate random data.
        Otherwise, read from the real sensor.
        """
        if self.mock:
            return {
                "sensor_id": self.sensor_id,
                "item_code": f"code_{int(np.random.uniform(1000, 10000))}",
                "item_name": f"Item-{int(np.random.uniform(1, 21))}",
                "item_category": np.random.choice(["Electronics", "Grocery", "Clothing", "Household"]),
                "price": round(np.random.uniform(10, 500), 2),
            }
        else:
            # Replace with actual sensor reading logic
            # TODO: Add code to read data from the real sensor
            return {
                "sensor_id": self.sensor_id,
                "item_code": "code_1234",
                "item_name": "Item-1",
                "item_category": "Electronics",
                "price": 100.0,
            }

    def stop(self):
        if not self.mock:
            # Shutdown procedures for the real sensor
            logging.info(f"Stopped real barcode sensor '{self.sensor_id}'")
            # TODO: Add real sensor shutdown code here
        else:
            logging.info(f"Stopped mock barcode sensor '{self.sensor_id}'")

def main():
    # Configuration
    config = read_barcode_config()
    setup_logging(config)
    
    # Create publishers
    publishers = create_publishers(config["publishers"])
    
    # Create sensors
    sensors = []
    for sensor_cfg in config["barcode_sensors"]:
        sensor = BarcodeSensor(
            sensor_id=sensor_cfg["id"],
            port=sensor_cfg["port"],
            mock=sensor_cfg["mock"]
        )
        sensors.append(sensor)
    
    shutdown = False
    def signal_handler(sig, frame):
        nonlocal shutdown
        logging.info("Shutting down...")
        shutdown = True
        
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Main loop
    publish_interval = config["global"].get("publish_interval", 1.0)
    while not shutdown:
        try:
            # Collect data from all sensors
            for sensor in sensors:
                readings = sensor.get_readings()
                for publisher in publishers:
                    publisher.publish(readings)
            
            time.sleep(publish_interval)
        except Exception as e:
            logging.error(f"Error in main loop: {str(e)}")
            if os.getenv("FAIL_FAST", "false").lower() == "true":
                raise e

    # Cleanup
    for sensor in sensors:
        sensor.stop()

if __name__ == "__main__":
    main()
