# Common-Service: LiDAR & Weight Sensor Microservice 
This microservice manages **both LiDAR and Weight sensors**  in a single container. It publishes sensor data over **MQTT** , **Kafka** , or **HTTP**  (or any combination), controlled entirely by environment variables.
## 1. Overview 
 
- **Sensors** 
  - LiDAR & Weight support in the same codebase.

  - Configuration for each sensor (e.g., ID, port, mock mode, intervals).
 
- **Publishing**  
  - `publisher.py` handles publishing to one or more protocols: 
    - **MQTT**
 
    - **Kafka**
 
    - **HTTP**
 
- **Apps**  
  - Two main modules: 
    - `lidar_app.py`
 
    - `weight_app.py`
 
  - Each uses shared methods from `publisher.py` & `config.py`.

## 2. Environment Variables 
All settings are defined in `docker-compose.yml` under the `asc_common_service` section. Key variables include:
### LiDAR 
| Variable | Description | Example | 
| --- | --- | --- | 
| LIDAR_COUNT | Number of LiDAR sensors | 2 | 
| LIDAR_SENSOR_ID_1 | Unique ID for first LiDAR sensor | lidar-001 | 
| LIDAR_SENSOR_ID_2 | Unique ID for second LiDAR sensor (if any) | lidar-002 | 
| LIDAR_MOCK_1 | Enable mock data for first LiDAR sensor (true/false) | true | 
| LIDAR_MQTT_ENABLE | Toggle MQTT publishing | true | 
| LIDAR_MQTT_BROKER_HOST | MQTT broker host | mqtt-broker or mqtt-broker_1 | 
| LIDAR_MQTT_BROKER_PORT | MQTT broker port | 1883 | 
| LIDAR_KAFKA_ENABLE | Toggle Kafka publishing | true | 
| KAFKA_BOOTSTRAP_SERVERS | Kafka bootstrap server addresses | kafka:9093 | 
| LIDAR_KAFKA_TOPIC | Kafka topic name for LiDAR data | lidar-data | 
| LIDAR_HTTP_ENABLE | Toggle HTTP publishing | true | 
| LIDAR_HTTP_URL | HTTP endpoint URL for LiDAR data | http://localhost:5000/api/lidar_data | 
| LIDAR_PUBLISH_INTERVAL | Interval (in seconds) for LiDAR data publishing | 1.0 | 
| LIDAR_LOG_LEVEL | Logging level (DEBUG, INFO, etc.) | INFO | 

### Weight 
| Variable | Description | Example | 
| --- | --- | --- | 
| WEIGHT_COUNT | Number of Weight sensors | 2 | 
| WEIGHT_SENSOR_ID_1 | Unique ID for first Weight sensor | weight-001 | 
| WEIGHT_SENSOR_ID_2 | Unique ID for second Weight sensor (if any) | weight-002 | 
| WEIGHT_MOCK_1 | Enable mock data for first Weight sensor (true/false) | true | 
| WEIGHT_MQTT_ENABLE | Toggle MQTT publishing | true | 
| WEIGHT_MQTT_BROKER_HOST | MQTT broker host | mqtt-broker_1 | 
| WEIGHT_MQTT_BROKER_PORT | MQTT broker port | 1883 | 
| WEIGHT_KAFKA_ENABLE | Toggle Kafka publishing | false | 
| WEIGHT_MQTT_TOPIC | MQTT topic name for Weight data | weight/data | 
| WEIGHT_HTTP_ENABLE | Toggle HTTP publishing | false | 
| WEIGHT_PUBLISH_INTERVAL | Interval (in seconds) for Weight data publishing | 1.0 | 
| WEIGHT_LOG_LEVEL | Logging level (DEBUG, INFO, etc.) | INFO | 

> **Note:**  Change `"true"` or `"false"` to enable or disable each protocol. Adjust intervals, logging levels, or sensor counts as needed.
## 3. Usage 
 
1. **Build and Run ** 

```bash
make run-demo
```
This spins up the `asc_common_service` container (and related services like Mosquitto or Kafka, depending on your configuration).
 
2. **Data Flow**  
  - By default, LiDAR publishes to `lidar/data` (MQTT, if enabled) or `lidar-data` (Kafka), or an HTTP endpoint if configured.
 
  - Weight sensor similarly publishes to `weight/data` or `weight-data`.
 
3. **Mock Mode**  
  - Setting `LIDAR_MOCK_1="true"` (or `WEIGHT_MOCK_1="true"`) forces the sensor to generate **random**  data rather than reading from actual hardware.

## 4. Testing 

### A. MQTT 
 
- **Grafana** : A pre-loaded dashboard named *Sensor-Analytics* is available at [http://localhost:3000](http://localhost:3000/)  (default credentials `admin`/`admin`).
 
- Check that the MQTT data source in Grafana points to `tcp://mqtt-broker_1:1883` (or `tcp://mqtt-broker:1883`, depending on the network).

### B. Kafka 
 
- Enable Kafka for LiDAR/Weight by setting `LIDAR_KAFKA_ENABLE="true"` and/or `WEIGHT_KAFKA_ENABLE="true"`.
 
- Test from inside the container:

```bash
docker exec asc_common_service python kafka_publisher_test.py --topic lidar-data
```
You should see incoming messages in the console.

### C. HTTP 
 
1️ **Local Test (Inside Docker)**

- Set `LIDAR_HTTP_URL="http://localhost:5000/api/lidar_data"` in the environment.
- Run `make run-demo` and wait for all containers to start.
- Once up, execute:

```bash
docker exec asc_common_service python http_publisher_test.py
```

- This will trigger the HTTP publisher and display the received data inside the container.

2️ **Using an External Webhook Service**

- Visit [Webhook.site](https://webhook.site/) and get a unique URL.
- Set `LIDAR_HTTP_URL` to this URL.
- Run `make run-demo`, and you should see the HTTP requests arriving on the Webhook.site dashboard.



## 5. Contributing & Development 
 
- **Code Structure**  
  - `publisher.py`: Core publishing logic (MQTT, Kafka, HTTP).
 
  - `config.py`: Loads environment variables and configures each sensor.
 
  - `lidar_app.py` and `weight_app.py`: Sensor-specific logic.