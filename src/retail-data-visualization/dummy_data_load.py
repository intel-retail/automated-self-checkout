from flask import Flask, jsonify, request
import random
import time
import threading
from flask_cors import CORS
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Dummy data generation functions
def generate_lidar_data():
    current_time = datetime.now()
    lidar_data = []
    for i in range(1, 21):
        timestamp = current_time - timedelta(minutes=(20 - i))  # Spread timestamps over 20 minutes
        length = round(random.uniform(10, 50), 2)
        width = round(random.uniform(10, 50), 2)
        height = round(random.uniform(10, 50), 2)
        lidar_data.append({
            "sensor_id": f"lidar_{i}",
            "length": length,
            "width": width,
            "height": height,
            "size": round(length * width * height, 2),
            "timestamp": timestamp.strftime("%Y-%m-%d %H:%M:%S")
        })
    return lidar_data

def generate_weight_data():
    current_time = datetime.now()
    weight_data = []
    for i in range(1, 21):
        timestamp = current_time - timedelta(minutes=(20 - i))  # Spread timestamps over 20 minutes
        weight_data.append({
            "sensor_id": f"weight_{i}",
            "weight_of_item": round(random.uniform(0.1, 10.0), 2),
            "item_id": f"item_{random.randint(1, 100)}",
            "timestamp": timestamp.strftime("%Y-%m-%d %H:%M:%S")
        })
    return weight_data

def generate_barcode_data():
    current_time = datetime.now()
    barcode_data = []
    for i in range(1, 21):
        timestamp = current_time - timedelta(minutes=(20 - i))  # Spread timestamps over 20 minutes
        barcode_data.append({
            "sensor_id": f"barcode_{i}",
            "item_code": f"code_{random.randint(1000, 9999)}",
            "item_name": f"Item-{i}",
            "item_category": random.choice(["Electronics", "Grocery", "Clothing", "Household"]),
            "price": round(random.uniform(10, 500), 2),
            "timestamp": timestamp.strftime("%Y-%m-%d %H:%M:%S")
        })
    return barcode_data

# Global sensor data
lidar_data = generate_lidar_data()
weight_sensor_data = generate_weight_data()
barcode_data = generate_barcode_data()

# Flask endpoints
@app.route('/lidar', methods=['GET'])
def get_lidar_data():
    """
    Endpoint to fetch LIDAR sensor data.
    Regenerate LIDAR data with updated timestamps on each call.
    """
    global lidar_data
    lidar_data = generate_lidar_data()
    return jsonify(lidar_data), 200

@app.route('/weight', methods=['GET'])
def get_weight_data():
    """
    Endpoint to fetch Weight sensor data.
    Regenerate Weight sensor data with updated timestamps on each call.
    """
    global weight_sensor_data
    weight_sensor_data = generate_weight_data()
    return jsonify(weight_sensor_data), 200

@app.route('/barcode', methods=['GET'])
def get_barcode_data():
    """
    Endpoint to fetch Barcode scanner data.
    Regenerate Barcode data with updated timestamps on each call.
    """
    global barcode_data
    barcode_data = generate_barcode_data()
    return jsonify(barcode_data), 200

def simulate_data_updates():
    """
    Simulate periodic updates for dummy sensor data.
    """
    global lidar_data, weight_sensor_data, barcode_data
    while True:
        # Regenerate data for all sensors
        lidar_data = generate_lidar_data()
        weight_sensor_data = generate_weight_data()
        barcode_data = generate_barcode_data()

        time.sleep(5)  # Simulate updates every 5 seconds

@app.before_request
def start_simulation():
    """
    Start the simulation in a separate thread when the Flask app starts.
    """
    thread = threading.Thread(target=simulate_data_updates)
    thread.daemon = True  # Ensure the thread exits when the app stops
    thread.start()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)
