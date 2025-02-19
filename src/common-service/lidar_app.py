# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#


import logging
import os
import signal
import time
import random
import math
from datetime import datetime
import numpy as np

from config.publisher import create_publishers
from config.config import read_lidar_config, setup_logging

class LidarSensor:
    """
    Example Lidar sensor class. Replace with real driver calls as needed.
    """
    def __init__(self, sensor_id, port, mock=False):
        self.sensor_id = sensor_id
        self.port = port
        self.mock = mock

        if not self.mock:
            # Initialize the real Lidar sensor (e.g., connect to the device)
            logging.info(f"Initialized real LiDAR sensor '{self.sensor_id}' on port {self.port}")
            # TODO: Add real sensor initialization code here
        else:
            logging.info(f"Initialized mock LiDAR sensor '{self.sensor_id}'")

    def get_readings(self):
        """
        Returns sensor readings. If mock, generate random or static data.
        Otherwise, read from the real sensor.
        """
        if self.mock:
            readings = []
            for angle in range(0, 360, 15):  # Simulate readings every 15 degrees
                distance = np.random.uniform(1.0, 10.0)
                intensity = np.random.uniform(0.1, 1.0)
                x = distance * math.cos(math.radians(angle))
                y = distance * math.sin(math.radians(angle))
                z = np.random.uniform(0.0, 0.5)  # Simulate small z variations
                readings.append({"x": x, "y": y, "z": z, "intensity": intensity})
            return readings
        else:
            # Replace with actual sensor reading logic
            # TODO: Add code to read data from the real sensor
            return [{"x": 0, "y": 0, "z": 0, "intensity": 1.0}]
        
    def stop(self):
        if not self.mock:
            # Shutdown procedures for the real sensor
            logging.info(f"Stopped real LiDAR sensor '{self.sensor_id}'")
            # TODO: Add real sensor shutdown code here
        else:
            logging.info(f"Stopped mock LiDAR sensor '{self.sensor_id}'")
        
    

def main():
    # Configuration
    config = read_lidar_config()
    setup_logging(config)
    
    # Create publishers
    publishers = create_publishers(config["publishers"])
    
    # Create sensors
    sensors = []
    for sensor_cfg in config["lidar_sensors"]:
        sensor = LidarSensor(
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
            sensors_data = []
            timestamp = datetime.utcnow().isoformat() + "Z"
            no_of_sensors = len(sensors)
            for sensor in sensors:
                readings = sensor.get_readings()
                sensor_data = {
                    "sensor_id": sensor.sensor_id,
                    "data": readings,
                }
                sensors_data.append(sensor_data)
            
            # Create a single payload containing data from all sensors
            payload = {
                "sensors": sensors_data,
                "sensor_count": no_of_sensors,
                "timestamp": timestamp
            }
            
            # Publish the combined payload
            for publisher in publishers:
                publisher.publish(payload)
            
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
    