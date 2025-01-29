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

### 1. Run the application

Navigate to retail-data-visualization and run the command

```bash
docker compose -f docker-compose.datavis.yml up -d
```
