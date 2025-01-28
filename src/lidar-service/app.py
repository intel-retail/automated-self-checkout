import os
import time
import json
import logging
import signal
import sys
from datetime import datetime
import random
import math

# Uncomment these if you're connecting to a real Lidar sensor library
# e.g., from rplidar import RPLidar
# import serial

###############################################################################
# 1. Configuration & Logging Setup
###############################################################################

def read_env():
    """
    Reads environment variables and returns a config dictionary with defaults.
    """
    return {
        # General
        "SENSOR_ID": os.getenv("SENSOR_ID", "lidar-001"),
        "MOCK_SENSOR": os.getenv("MOCK_SENSOR", "true").lower() == "true",  # Use "false" for real sensor

        # Lidar Sensor Port / Connection
        "SENSOR_PORT": os.getenv("SENSOR_PORT", "/dev/ttyUSB0"),  
        "PUBLISH_INTERVAL": float(os.getenv("PUBLISH_INTERVAL", "1.0")),  # in seconds

        # MQTT
        "MQTT_ENABLE": os.getenv("MQTT_ENABLE", "true").lower() == "true",
        "MQTT_BROKER_HOST": os.getenv("MQTT_BROKER_HOST", "localhost"),
        "MQTT_BROKER_PORT": int(os.getenv("MQTT_BROKER_PORT", "1883")),
        "MQTT_TOPIC": os.getenv("MQTT_TOPIC", "lidar/data"),

        # Kafka
        "KAFKA_ENABLE": os.getenv("KAFKA_ENABLE", "false").lower() == "true",
        "KAFKA_BOOTSTRAP_SERVERS": os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092"),
        "KAFKA_TOPIC": os.getenv("KAFKA_TOPIC", "lidar-data"),

        # HTTP
        "HTTP_ENABLE": os.getenv("HTTP_ENABLE", "false").lower() == "true",
        "HTTP_PUBLISH_URL": os.getenv("HTTP_PUBLISH_URL", "http://localhost:5000/lidar"),

        # Logging
        "LOG_LEVEL": os.getenv("LOG_LEVEL", "INFO"),
    }


def setup_logging(level_str):
    """
    Sets up Python logging with the desired log level.
    """
    level = getattr(logging, level_str.upper(), logging.INFO)
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    logging.info(f"Log level set to {level_str.upper()}")

###############################################################################
# 2. Publishers
###############################################################################

class BasePublisher:
    """
    Abstract base class for all publishers.
    """
    def publish(self, payload: dict):
        """
        Publishes the given payload. Must be implemented by subclass.
        """
        raise NotImplementedError()

class MqttPublisher(BasePublisher):
    def __init__(self, host, port, topic):
        import paho.mqtt.client as mqtt  # Lazy import
        self.host = host
        self.port = port
        self.topic = topic
        self.client = mqtt.Client()
        self._configure_client()
        self._connect_with_retry()

    def _configure_client(self):
        """Configure MQTT client settings and callbacks"""
        self.client.on_connect = self._on_connect
        self.client.on_disconnect = self._on_disconnect
        self.client.reconnect_delay_set(min_delay=1, max_delay=30)
        # Optional: Set Last Will and Testament (LWT)
        self.client.will_set(
            topic=f"{self.topic}/status",
            payload="offline",
            qos=1,
            retain=True
        )

    def _connect_with_retry(self, max_attempts=3):
        """Attempt connection with retry logic"""
        for attempt in range(1, max_attempts+1):
            try:
                self.client.connect(self.host, self.port, keepalive=60)
                self.client.loop_start()  # Start background network loop
                logging.info(f"Connected to MQTT broker at {self.host}:{self.port}")
                return
            except Exception as e:
                logging.error(f"Connection attempt {attempt}/{max_attempts} failed: {e}")
                if attempt < max_attempts:
                    time.sleep(2 ** attempt)  # Exponential backoff
        logging.error("All connection attempts failed. MQTT publisher disabled.")

    def _on_connect(self, client, userdata, flags, rc):
        """Callback for when the client connects to the broker"""
        if rc == 0:
            logging.info("MQTT connection established")
            # Publish online status
            client.publish(
                topic=f"{self.topic}/status",
                payload="online",
                qos=1,
                retain=True
            )
        else:
            logging.error(f"MQTT connection failed with code: {rc}")

    def _on_disconnect(self, client, userdata, rc):
        """Callback for unexpected disconnections"""
        logging.warning(f"MQTT disconnected (reason: {rc}). Will attempt reconnect")

    def publish(self, payload: dict):
        """Publish with delivery confirmation and error handling"""
        if not self.client.is_connected():
            logging.warning("MQTT client not connected during publish attempt")
            
        try:
            msg_str = json.dumps(payload)
            message_info = self.client.publish(
                topic=self.topic,
                payload=msg_str,
                qos=1  # At least once delivery
            )
            
            # Wait for publish confirmation (non-blocking with timeout)
            if message_info.wait_for_publish(timeout=5):
                logging.debug(f"MQTT published to {self.topic}: {msg_str}")
            else:
                logging.error("MQTT message confirmation timeout")
                
        except Exception as e:
            logging.error(f"MQTT publish error: {str(e)}")
            # Re-raise if you want to handle this at a higher level

class KafkaPublisher(BasePublisher):
    def __init__(self, bootstrap_servers, topic):
        from kafka import KafkaProducer  # Lazy import
        self.bootstrap_servers = bootstrap_servers
        self.topic = topic
        try:
            self.producer = KafkaProducer(
                bootstrap_servers=self.bootstrap_servers,
                value_serializer=lambda v: json.dumps(v).encode("utf-8")
            )
            logging.info(f"Connected to Kafka at {self.bootstrap_servers}")
        except Exception as e:
            logging.error(f"Failed to connect to Kafka: {e}")

    def publish(self, payload: dict):
        """
        Publishes JSON payload to the configured Kafka topic.
        """
        try:
            self.producer.send(self.topic, payload)
            logging.debug(f"Kafka published to {self.topic}: {payload}")
        except Exception as e:
            logging.error(f"Kafka publish error: {e}")

class HttpPublisher(BasePublisher):
    def __init__(self, url):
        import requests  # Lazy import
        self.url = url
        self.requests = requests
        logging.info(f"HTTP publisher initialized for {self.url}")

    def publish(self, payload: dict):
        """
        Sends a POST request with JSON payload to the configured HTTP URL.
        """
        try:
            response = self.requests.post(self.url, json=payload, timeout=5)
            response.raise_for_status()
            logging.debug(f"HTTP POST to {self.url} succeeded: {payload}")
        except Exception as e:
            logging.error(f"HTTP publish error: {e}")


def create_publishers(config):
    """
    Based on the config dictionary, instantiate the appropriate publishers.
    Returns a list of publisher instances.
    """
    publishers = []

    if config["MQTT_ENABLE"]:
        publishers.append(
            MqttPublisher(
                host=config["MQTT_BROKER_HOST"],
                port=config["MQTT_BROKER_PORT"],
                topic=config["MQTT_TOPIC"],
            )
        )

    if config["KAFKA_ENABLE"]:
        publishers.append(
            KafkaPublisher(
                bootstrap_servers=config["KAFKA_BOOTSTRAP_SERVERS"],
                topic=config["KAFKA_TOPIC"],
            )
        )

    if config["HTTP_ENABLE"]:
        publishers.append(
            HttpPublisher(
                url=config["HTTP_PUBLISH_URL"],
            )
        )

    if not publishers:
        logging.warning("No publishers are enabled! Data will not be sent anywhere.")
    return publishers

###############################################################################
# 3. Sensor Handling (Mock or Real)
###############################################################################

class LidarSensor:
    """
    Example Lidar sensor class. Replace with real driver calls as needed.
    """
    def __init__(self, port, mock=False):
        self.port = port
        self.mock = mock

        if not self.mock:
            # Here you'd open a serial port or use an actual Lidar library
            # e.g., self.lidar = RPLidar(port)
            logging.info(f"Initialized real Lidar sensor on port {port}")
        else:
            logging.info("Initialized mock Lidar sensor")

    def get_readings(self):
        """
        Returns a list of readings. If mock, generate random or static data.
        Otherwise, read from the real sensor.
        """
        if self.mock:
            readings = []
            for angle in range(0, 360, 15):  # Simulate readings every 15 degrees
                distance = random.uniform(1.0, 10.0)  # Distance in meters
                intensity = random.uniform(0.1, 1.0)  # Simulated intensity (0.1 - 1.0)
                x = distance * math.cos(math.radians(angle))
                y = distance * math.sin(math.radians(angle))
                z = random.uniform(0.0, 0.5)  # Simulate small z variations
                readings.append({"x": x, "y": y, "z": z, "intensity": intensity})
            return readings
        else:
            # Real sensor reading logic
            # Example for a library-based approach:
            #
            # info = next(self.lidar.iter_scans(max_buf_meas=500))
            # # info is a list of tuples: (quality, angle, distance)
            # readings = []
            # for _, angle, distance in info:
            #     readings.append({"angle": angle, "distance": distance})
            # return readings
            #
            # For now, just simulate we have something
            return [{"angle": 0, "distance": 123}, {"angle": 90, "distance": 456}]

###############################################################################
# 4. Main Loop
###############################################################################

def main():
    # 4.1. Read configuration & setup logging
    config = read_env()
    setup_logging(config["LOG_LEVEL"])
    logging.info("Starting Lidar microservice...")

    # 4.2. Instantiate sensor
    sensor = LidarSensor(port=config["SENSOR_PORT"], mock=config["MOCK_SENSOR"])

    # 4.3. Create publishers
    publishers = create_publishers(config)

    # 4.4. Publish loop control (graceful shutdown)
    shutdown_requested = False

    def handle_signal(signum, frame):
        nonlocal shutdown_requested
        logging.info(f"Received signal {signum}. Shutting down...")
        shutdown_requested = True

    signal.signal(signal.SIGINT, handle_signal)   # CTRL+C
    signal.signal(signal.SIGTERM, handle_signal)  # Docker stop

    # 4.5. Main loop
    while not shutdown_requested:
        try:
            # Get sensor data
            readings = sensor.get_readings()

            # Build the payload
            payload = {
                "sensor_id": config["SENSOR_ID"],
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "readings": readings
            }

            # Publish to all configured destinations
            for pub in publishers:
                pub.publish(payload)

            # Sleep for the configured interval
            time.sleep(config["PUBLISH_INTERVAL"])

        except Exception as e:
            logging.error(f"Unexpected error in main loop: {e}")
            # Continue or break depending on your policy
            # If it's fatal, do a break, or try reconnect logic

    logging.info("Microservice has stopped gracefully.")

###############################################################################
# 5. Entry Point
###############################################################################

if __name__ == "__main__":
    main()
