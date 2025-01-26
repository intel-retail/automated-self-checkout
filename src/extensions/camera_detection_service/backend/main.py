from flask import Flask, jsonify

app = Flask(__name__)

# Dummy camera data
dummy_cameras = {
    "camera_001": {
        "id": "camera_001",
        "type": "wired",
        "connection": "USB",
         "index": 0,  # Add this field
        "status": "active",
        "name": "Logitech HD Webcam",
        "resolution": "1920x1080",
        "fps": 30,
        "ip": None,  # Wired cameras don't have an IP
        "port": None  # Wired cameras don't have a port
    },
    "camera_002": {
        "id": "camera_002",
        "type": "wireless",
        "connection": "Wi-Fi",
        "status": "active",
         "index": 1,  # Add this field
        "name": "Arlo Pro 3",
        "resolution": "2560x1440",
        "fps": 25,
        "ip": "192.168.1.102",
        "port": 554
    },
    "camera_003": {
        "id": "camera_003",
        "type": "wired",
        "connection": "HDMI",
         "index": 2,  # Add this field
        "status": "inactive",
        "name": "Sony Alpha a6400",
        "resolution": "3840x2160",
        "fps": 60,
        "ip": None,
        "port": None
    }
}

@app.route('/cameras', methods=['GET'])
def get_all_cameras():
    return jsonify({
        "cameras": list(dummy_cameras.values()),  # Changed key from connected_cameras to cameras
        "message": "Cameras retrieved successfully",
        "total_cameras": len(dummy_cameras)
    })



@app.route('/cameras/<camera_id>', methods=['GET'])
def get_camera_details(camera_id):
    """
    Returns details for a specific camera.
    """
    camera = dummy_cameras.get(camera_id)
    if not camera:
        return jsonify({
            "error": "Camera not found",
            "message": f"No camera with ID '{camera_id}' exists."
        }), 404

    return jsonify(camera)


@app.route('/scan', methods=['POST'])
def scan_cameras():
    """
    Simulates a scan for cameras and returns the updated list.
    This is dummy data and does not perform a real scan.
    """
    # In a real-world scenario, scanning logic would go here.
    return jsonify({
        "message": "Scan completed successfully",
        "total_cameras": len(dummy_cameras),
        "connected_cameras": list(dummy_cameras.values())
    })


@app.route('/status', methods=['GET'])
def get_status():
    """
    Returns the service status and basic statistics.
    """
    return jsonify({
        "status": "running",
        "total_cameras_detected": len(dummy_cameras),
        "last_scan_time": "2025-01-25T15:30:00Z"  # Dummy timestamp for testing
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
