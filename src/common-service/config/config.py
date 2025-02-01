# common/config.py
import os
import logging
from typing import Dict

def read_lidar_config() -> Dict:
    """
    Read environment variables for LiDAR configuration
    and return them as a dictionary.
    """
    config = {
        "lidar_count": int(os.getenv("LIDAR_COUNT", "1")),
        "lidar_sensors": [],
        "publishers": {
            "mqtt": {
                "enable": os.getenv("LIDAR_MQTT_ENABLE", "false").lower() == "true",
                "host": os.getenv("LIDAR_MQTT_BROKER_HOST", "localhost"),
                "port": int(os.getenv("LIDAR_MQTT_BROKER_PORT", "1883")),
                "topic": os.getenv("LIDAR_MQTT_TOPIC", "lidar/data")
            },
            "http": {
                "enable": os.getenv("LIDAR_HTTP_ENABLE", "false").lower() == "true",
                "url": os.getenv("LIDAR_HTTP_URL", "")
            },
            "kafka": {
                "enable": os.getenv("LIDAR_KAFKA_ENABLE", "false").lower() == "true",
                "bootstrap_servers": os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092"),
                "topic": os.getenv("LIDAR_KAFKA_TOPIC", "lidar-data")
            }
        },
        "global": {
            "log_level": os.getenv("LIDAR_LOG_LEVEL", "INFO"),
            "publish_interval": float(os.getenv("LIDAR_PUBLISH_INTERVAL", "1.0"))
        }
    }

    # Load individual LiDAR sensor configurations
    for i in range(1, config["lidar_count"] + 1):
        sensor = {
            "id": os.getenv(f"LIDAR_SENSOR_ID_{i}", f"lidar-{i:03}"),
            "port": os.getenv(f"LIDAR_PORT_{i}", f"/dev/ttyUSB{i-1}"),
            "mock": os.getenv(f"LIDAR_MOCK_{i}", "true").lower() == "true",
            "publish_interval": float(
                os.getenv(f"LIDAR_PUBLISH_INTERVAL_{i}", config["global"]["publish_interval"])
            )
        }
        config["lidar_sensors"].append(sensor)
    
    return config


def read_weight_config() -> Dict:
    """
    Read environment variables for Weight Sensor configuration
    and return them as a dictionary.
    """
    config = {
        "weight_count": int(os.getenv("WEIGHT_COUNT", "1")),
        "weight_sensors": [],
        "publishers": {
            "mqtt": {
                "enable": os.getenv("WEIGHT_MQTT_ENABLE", "false").lower() == "true",
                "host": os.getenv("WEIGHT_MQTT_BROKER_HOST", "localhost"),
                "port": int(os.getenv("WEIGHT_MQTT_BROKER_PORT", "1883")),
                "topic": os.getenv("WEIGHT_MQTT_TOPIC", "weight/data")
            },
            "http": {
                "enable": os.getenv("WEIGHT_HTTP_ENABLE", "false").lower() == "true",
                "url": os.getenv("WEIGHT_HTTP_URL", "")
            },
            "kafka": {
                "enable": os.getenv("WEIGHT_KAFKA_ENABLE", "false").lower() == "true",
                "bootstrap_servers": os.getenv("WEIGHT_KAFKA_BOOTSTRAP_SERVERS", "localhost:9092"),
                "topic": os.getenv("WEIGHT_KAFKA_TOPIC", "weight-data")
            }
        },
        "global": {
            "log_level": os.getenv("WEIGHT_LOG_LEVEL", "INFO"),
            "publish_interval": float(os.getenv("WEIGHT_PUBLISH_INTERVAL", "1.0"))
        }
    }

    # Load individual Weight Sensor configurations
    for i in range(1, config["weight_count"] + 1):
        sensor = {
            "id": os.getenv(f"WEIGHT_SENSOR_ID_{i}", f"weight-{i:03}"),
            "port": os.getenv(f"WEIGHT_PORT_{i}", f"/dev/ttyUSB{i-1}"),
            "mock": os.getenv(f"WEIGHT_MOCK_{i}", "true").lower() == "true",
            "publish_interval": float(
                os.getenv(f"WEIGHT_PUBLISH_INTERVAL_{i}", config["global"]["publish_interval"])
            )
        }
        config["weight_sensors"].append(sensor)
    
    return config


def setup_logging(config: Dict):
    """
    Configure logging from a given config dictionary.
    Expects 'log_level' under config["global"].
    """
    level_name = config["global"].get("log_level", "INFO")
    level = getattr(logging, level_name, logging.INFO)
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    logging.info(f"Logging configured at {level_name} level")
