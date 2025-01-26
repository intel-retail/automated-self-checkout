## Features
- **LIDAR Data:** Simulated LIDAR sensor data including length, width, height, and size.
- **Weight Data:** Simulated weight sensor data with the weight of items and item IDs.
- **Barcode Data:** Simulated barcode scanner data including item code, item name, category, and price.
- **Periodic Data Updates:** Sensor data is automatically regenerated and updated every 5 seconds.

## API Endpoints

1. **Get LIDAR Data**
   - **Endpoint:** `/lidar`
   - **Method:** `GET`
   - **Description:** Fetches the simulated LIDAR sensor data. Data is regenerated each time this endpoint is called.
   - **Response:** A JSON array containing sensor data, including length, width, height, size, and timestamp.

2. **Get Weight Data**
   - **Endpoint:** `/weight`
   - **Method:** `GET`
   - **Description:** Fetches the simulated weight sensor data. Data is regenerated each time this endpoint is called.
   - **Response:** A JSON array containing weight sensor data with weight, item ID, and timestamp.

3. **Get Barcode Data**
   - **Endpoint:** `/barcode`
   - **Method:** `GET`
   - **Description:** Fetches the simulated barcode scanner data. Data is regenerated each time this endpoint is called.
   - **Response:** A JSON array containing barcode data, including item code, item name, category, price, and timestamp.

## Requirements

To run this Flask application, you will need the following:

- **Docker (for containerization)**

## Setup and Installation

### 1. Build the Docker Image

To build the Docker image, run the following command in the directory containing the `Dockerfile` and `requirements.txt`:

```bash
docker build -t grafana-dashboard . .
```
This command will build the Docker image and tag it as flask-sensor-app.

### 2. Run the Docker Container

Once the image is built, run the Docker container using the following command:

bash
```
docker run -p 3000:3000 grafana-dashboard
```

This will start the application inside a Docker container and map port 3000 on your local machine to port 3000 inside the container. You can access the API at http://localhost:3000.

### 3. Verify the Application is Running

Once the container is running, you can verify that the application is working by accessing the following endpoints:

    http://localhost:3000/lidar (Get LIDAR data)
    http://localhost:3000/weight (Get Weight data)
    http://localhost:3000/barcode (Get Barcode data)

You can also use curl to test the endpoints, for example:

bash
```
curl http://localhost:3000/lidar
curl http://localhost:3000/weight
curl http://localhost:3000/barcode
```

## Automatic Data Updates

The Flask application automatically updates the sensor data every 5 seconds. This is done by a background thread that regenerates the sensor data periodically.
