from flask import Flask, jsonify
from util import scan_wired_cameras, scan_network_cameras, get_dummy_cameras

USE_DUMMY_DATA = True  # Set to False to use real scanning

app = Flask(__name__)



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
    Scans the system and network for connected cameras.
    """
    try:
        if USE_DUMMY_DATA:
            # Use dummy data
            connected_cameras = get_dummy_cameras()
        else:
            # Use real scanning
            wired_cameras = scan_wired_cameras()
            network_cameras = scan_network_cameras()
            connected_cameras = wired_cameras + network_cameras

        return jsonify({
            "message": "Scan completed successfully",
            "total_cameras": len(connected_cameras),
            "connected_cameras": connected_cameras
        })
    except Exception as e:
        return jsonify({
            "error": "Failed to scan cameras",
            "message": str(e)
        }), 500


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
