# RealSense Sensor Data Extractor

This project is designed to continuously poll data from an Intel RealSense camera. It extracts height, width, and depth information from the frames and pushes the data to Kafka, Grafana, and another microservice configured in the configuration file.

---

## Features
- Continuously polls data from the RealSense camera.
- Extracts frame details: height, width, and depth.
- Publishes data to:
  - **Kafka**
  - **Grafana**
  - **A configurable microservice**

---

## Requirements
- Python 3.7+
- Docker
- pyrealsense2
- numpy
- opencv-python
- requests
- influxdb-client
- confluent-kafka

---

## Configuration

Before running the service, ensure that the appropriate values are set in the `RealSenseConfig.json` file. This configuration file defines the necessary details for:
- RealSense camera settings
- Kafka topic configuration
- Grafana publisher setup
- Other microservice details

---

## How to Run

### 1.Create and run the Docker container(s)
```bash
make up
```

### 2. Shut down the Docker container(s)
```bash
make down
```

---

## Running Unit Tests

Unit tests are available for all the publishers. To run the tests, execute the following commands:
before running the unit tests make sure all the dependencies specified in requirements.txt are installed

### Running Unit Tests
```bash
make test
```

---

## File Details

### `pollRealSenseSensor.py`
The main script that continuously polls data from the RealSense camera and pushes it to the respective services.

### `RealSenseConfig.json`
The configuration file used to define:
- RealSense camera parameters
- Kafka, Grafana, and microservice integration details

---

## Notes
- Ensure that the RealSense camera is properly connected and the necessary drivers are installed.
- Check and modify the `RealSenseConfig.json` file as per your environment and requirements.

---

## Author
Hemanth Reddy Chittepu<br>
Hemanth Varma Sangaraju<br>
Saketh Reddy Chandupatla
