# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

import json
import logging
import os
import time
from abc import ABC, abstractmethod

def create_publishers(publishers_cfg: dict):
    """
    publishers_cfg will look like:
    {
      "mqtt": { "enable": bool, "host": str, "port": int, "topic": str },
      "http": { "enable": bool, "url": str },
      "kafka": { "enable": bool, "bootstrap_servers": str, "topic": str }
    }
    """
    publishers = []

    # MQTT
    mqtt_cfg = publishers_cfg.get("mqtt", {})
    if mqtt_cfg.get("enable", False):
        logging.info("Enabling MQTT Publisher")
        publishers.append(
            MqttPublisher(
                host=mqtt_cfg["host"],
                port=mqtt_cfg["port"],
                topic=mqtt_cfg["topic"]
            )
        )

    # Kafka
    kafka_cfg = publishers_cfg.get("kafka", {})
    if kafka_cfg.get("enable", False):
        logging.info("Enabling Kafka Publisher")
        publishers.append(
            KafkaPublisher(
                bootstrap_servers=kafka_cfg["bootstrap_servers"],
                topic=kafka_cfg["topic"]
            )
        )

    # HTTP
    http_cfg = publishers_cfg.get("http", {})
    if http_cfg.get("enable", False):
        logging.info("Enabling HTTP Publisher")
        publishers.append(
            HttpPublisher(
                url=http_cfg["url"]
            )
        )

    return publishers

class BasePublisher(ABC):
    @abstractmethod
    def publish(self, payload: dict):
        pass


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
        """Attempt connection with basic retry logic"""
        for attempt in range(1, max_attempts + 1):
            try:
                self.client.connect(self.host, self.port, keepalive=60)
                self.client.loop_start()  # Start background network loop
                logging.info(f"Connected to MQTT broker at {self.host}:{self.port}")
                return
            except Exception as e:
                logging.error(f"MQTT connection attempt {attempt}/{max_attempts} failed: {e}")
                if attempt < max_attempts:
                    time.sleep(2 ** attempt)  # Exponential backoff
        logging.error("All MQTT connection attempts failed. MQTT publisher disabled.")

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


class KafkaPublisher(BasePublisher):
    def __init__(self, bootstrap_servers, topic):
        from kafka import KafkaProducer
        from kafka.errors import KafkaError, NoBrokersAvailable

        self.bootstrap_servers = bootstrap_servers
        self.topic = topic
        self.max_retries = 5
        self.retry_delay = 1  # seconds
        self.producer = None
        self._running = False
        self._connect_with_retry()

    def _connect_with_retry(self):
        """Attempt connection with exponential backoff"""
        from kafka.errors import KafkaError, NoBrokersAvailable

        for attempt in range(self.max_retries):
            try:
                from kafka import KafkaProducer  # Safe re-import
                self.producer = KafkaProducer(
                    bootstrap_servers=self.bootstrap_servers,
                    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
                    acks='all',  # Ensure full commit
                    retries=3, 
                    max_in_flight_requests_per_connection=1,
                    security_protocol=os.getenv("KAFKA_SECURITY_PROTOCOL", "PLAINTEXT"),
                    ssl_cafile=os.getenv("KAFKA_SSL_CAFILE"),
                    ssl_certfile=os.getenv("KAFKA_SSL_CERTFILE"),
                    ssl_keyfile=os.getenv("KAFKA_SSL_KEYFILE"),
                )
                logging.info(f"Connected to Kafka at {self.bootstrap_servers}")
                self._running = True
                return
            except NoBrokersAvailable as e:
                logging.error(f"Kafka connection attempt {attempt+1}/{self.max_retries} failed: {e}")
                if attempt < self.max_retries - 1:
                    delay = self.retry_delay * (2 ** attempt)
                    time.sleep(delay)
            except KafkaError as e:
                logging.error(f"Fatal Kafka error: {e}")
                break

        logging.error("All Kafka connection attempts failed. Kafka publisher disabled.")
        self._running = False

    def publish(self, payload: dict):
        if not self._running or self.producer is None:
            logging.warning("Kafka publisher not connected or producer not initialized.")
            return

        try:
            future = self.producer.send(
                topic=self.topic,
                value=payload,
                headers=[('source', os.getenv("SENSOR_ID", "unknown").encode())]
            )
            # Block until message is sent with timeout
            record_metadata = future.get(timeout=10)
            logging.debug(
                f"Kafka published to {self.topic} "
                f"[partition {record_metadata.partition}] "
                f"offset {record_metadata.offset}"
            )
        except Exception as e:
            logging.error(f"Kafka publish error: {e}")
            self._handle_kafka_error(e)

    def _handle_kafka_error(self, error):
        from kafka.errors import NotLeaderForPartitionError, RequestTimedOutError
        if isinstance(error, (NotLeaderForPartitionError, RequestTimedOutError)):
            # Transient errors can sometimes be retried
            logging.warning("Transient Kafka error, forcing reconnect.")
            self._running = False
            if self.producer:
                self.producer.flush()
                self.producer.close()
            # Attempt reconnect
            self._connect_with_retry()
        else:
            logging.error("Non-retriable Kafka error, disabling publisher.")
            self._running = False
            if self.producer:
                self.producer.flush()
                self.producer.close()

    def __del__(self):
        if self.producer is not None:
            try:
                self.producer.flush(timeout=5)
                self.producer.close()
            except Exception as e:
                logging.error(f"Error while closing Kafka producer: {e}")

class HttpPublisher(BasePublisher):
    def __init__(self, url):
        import requests
        from requests.adapters import HTTPAdapter
        from urllib3.util.retry import Retry

        self.url = url
        self.max_retries = 3
        self.timeout = 10
        self.circuit_open = False
        self.circuit_reset_time = 0

        retry_strategy = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["POST"]
        )

        self.session = requests.Session()
        adapter = HTTPAdapter(max_retries=retry_strategy)
        self.session.mount("https://", adapter)
        self.session.mount("http://", adapter)

        # Optional Auth
        if os.getenv("HTTP_AUTH_TOKEN"):
            self.session.headers.update({
                "Authorization": f"Bearer {os.getenv('HTTP_AUTH_TOKEN')}"
            })

        logging.info(f"HTTP publisher initialized for {self.url}")

    def publish(self, payload: dict):
        # Circuit breaker check
        if self.circuit_open:
            if time.time() < self.circuit_reset_time:
                logging.warning("Circuit breaker open, skipping HTTP publish")
                return
            # Otherwise, reset the circuit
            self.circuit_open = False

        try:
            response = self.session.post(
                self.url,
                json=payload,
                timeout=self.timeout,
                headers={"X-Sensor-ID": os.getenv("SENSOR_ID", "unknown")}
            )
            response.raise_for_status()
            logging.debug(f"HTTP POST to {self.url} succeeded: {response.status_code}")

        except Exception as e:
            logging.error(f"HTTP publish error: {str(e)}")
            self._handle_error(e)

    def _handle_error(self, error):
        from requests.exceptions import ConnectionError, Timeout
        # Basic circuit-breaker logic
        if isinstance(error, (ConnectionError, Timeout)):
            self._trip_circuit_breaker()

    def _trip_circuit_breaker(self):
        if not self.circuit_open:
            logging.error("Tripping circuit breaker for HTTP publisher")
            self.circuit_open = True
            self.circuit_reset_time = time.time() + 60  # 1 minute cooldown

    def __del__(self):
        self.session.close()
