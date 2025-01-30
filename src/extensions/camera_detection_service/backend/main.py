# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

from flask import Flask, jsonify
from util import scan_wired_cameras, scan_network_cameras, get_dummy_cameras, store_cameras_to_file, read_actual_cameras
import os
from datetime import datetime, timezone  # Correct import for timestamp handling
import logging

# Configure logging
logging.basicConfig(level=logging.ERROR)  # Ensure errors are logged properly
logger = logging.getLogger(__name__)

USE_DUMMY_DATA = False  # Set to False to use real scanning

app = Flask(__name__)



@app.route('/cameras', methods=['GET'])
def get_all_cameras():
    if not USE_DUMMY_DATA:
        # Read the actual cameras from the file
        connected_cameras = read_actual_cameras("scanned_cameras.txt")
        return jsonify({
            "cameras": connected_cameras,
            "message": "Cameras retrieved successfully",
            "total_cameras": len(connected_cameras)
        })
    return jsonify({
        "cameras": get_dummy_cameras(),  # Changed key from connected_cameras to cameras
        "message": "Cameras retrieved successfully",
        "total_cameras": len(get_dummy_cameras())
    })

def get_camera_by_id(camera_id):
    """
    Retrieves a specific camera by its ID from the connected cameras or dummy cameras.
    """
    # Check if not using dummy data
    if not USE_DUMMY_DATA:
        connected_cameras = read_actual_cameras("scanned_cameras.txt")

        # Check if connected_cameras is loaded properly
        if connected_cameras:
            # Search for the camera in connected_cameras
            for _, camera_data in connected_cameras.items():
                if camera_data["id"] == camera_id:
                    return camera_data

    # Fallback to dummy cameras
    for camera in get_dummy_cameras():
        if camera["id"] == camera_id:
            return camera

    # If no match is found
    return None

@app.route('/cameras/<camera_id>', methods=['GET'])
def get_camera_details(camera_id):
    """
    Returns details for a specific camera by its ID.
    """
    try:
        # Use the helper function to get the camera
        camera = get_camera_by_id(camera_id)

        # Handle case where camera is not found
        if not camera:
            return jsonify({
                "error": "Camera not found",
                "message": f"No camera with ID '{camera_id}' exists."
            }), 404

        # Return the camera details
        return jsonify({
            "message": "Camera details retrieved successfully",
            "camera": camera
        }), 200

    except Exception as e:
        logger.error("Failed to scan cameras: %s", str(e))  # Log the actual error for debugging
        # General exception handler
        return jsonify({
            "error": "Failed to scan cameras",
            "message": "An unexpected error occurred. Please try again later."
        }), 500

@app.route('/scan', methods=['POST'])
def scan_cameras():
    """
    Scans the system and network for connected cameras.
    """
    try:
        if USE_DUMMY_DATA:
            # Use dummy data
            connected_cameras = get_dummy_cameras()
        else:
            # Use real scanning
            wired_cameras, next_index = scan_wired_cameras(start_index=1)
            network_cameras, _ = scan_network_cameras(start_index=next_index)
            connected_cameras = wired_cameras + network_cameras
        # Store the scanned cameras in a file
        store_cameras_to_file(connected_cameras)

        return jsonify({
            "message": "Scan completed successfully",
            "total_cameras": len(connected_cameras),
            "connected_cameras": connected_cameras
        })
    except Exception as e:
        logger.error("Failed to scan cameras: %s", str(e))  # Log the actual error for debugging
        return jsonify({
            "error": "Failed to scan cameras",
            "message": "An unexpected error occurred. Please try again later."
        }), 500


@app.route('/status', methods=['GET'])
def get_status():
    """
    Returns the service status and basic statistics.
    """
    if USE_DUMMY_DATA:
        connected_cameras = len(get_dummy_cameras())
        last_scan_time = "2025-01-25T15:30:00Z"
    else:
        current_dir = os.path.dirname(os.path.abspath(__file__))
        file_path = os.path.join(current_dir, "scanned_cameras.txt")
        
        connected_cameras = 0
        last_scan_time = None

        if os.path.exists(file_path):
            try:
                with open(file_path, 'r') as f:
                    connected_cameras = sum(1 for _ in f)
            except Exception as e:
                print(f"Error reading camera file: {e}")

            # Fixed timestamp conversion
            mod_time = os.path.getmtime(file_path)
            last_scan_dt = datetime.fromtimestamp(mod_time, tz=timezone.utc)  # Now using correct datetime class
            last_scan_time = last_scan_dt.replace(microsecond=0).isoformat()

    return jsonify({
        "status": "running",
        "total_cameras_detected": connected_cameras,
        "last_scan_time": last_scan_time
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
