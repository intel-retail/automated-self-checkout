#
# Copyright (C) 2025 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

from flask import Flask, jsonify
import numpy as np
import time
import threading
from flask_cors import CORS

app = Flask(__name__)
CORS(app) 

def generate_lidar_data():
    lidar_data = []
    for i in range(1, 21):
        length = round(np.random.uniform(10, 50), 2)  
        width = round(np.random.uniform(10, 50), 2)   
        height = round(np.random.uniform(10, 50), 2)  
        lidar_data.append({
            "sensor_id": f"lidar_{i}",
            "length": length,
            "width": width,
            "height": height,
            "size": round(length * width * height, 2),
        })
    return lidar_data

def generate_weight_data():
    weight_data = []
    for i in range(1, 21):
        weight_data.append({
            "sensor_id": f"weight_{i}",
            "weight_of_item": round(np.random.uniform(0.1, 10.0), 2),  
            "item_id": f"item_{int(np.random.uniform(1, 101))}",  
        })
    return weight_data

def generate_barcode_data():
    barcode_data = []
    for i in range(1, 21):
        barcode_data.append({
            "sensor_id": f"barcode_{i}",
            "item_code": f"code_{int(np.random.uniform(1000, 10000))}",  
            "item_name": f"Item-{i}",
            "item_category": np.random.choice(["Electronics", "Grocery", "Clothing", "Household"]),
            "price": round(np.random.uniform(10, 500), 2),  
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
    """
    global weight_sensor_data
    weight_sensor_data = generate_weight_data()
    return jsonify(weight_sensor_data), 200

@app.route('/barcode', methods=['GET'])
def get_barcode_data():
    """
    Endpoint to fetch Barcode scanner data.
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
        lidar_data = generate_lidar_data()
        weight_sensor_data = generate_weight_data()
        barcode_data = generate_barcode_data()

        time.sleep(5)  

@app.before_request
def start_simulation():
    """
    Start the simulation in a separate thread when the Flask app starts.
    """
    thread = threading.Thread(target=simulate_data_updates)
    thread.daemon = True  
    thread.start()

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8000)
