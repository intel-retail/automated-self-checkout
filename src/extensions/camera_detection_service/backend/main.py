from flask import Flask, jsonify
from util import scan_wired_cameras, scan_network_cameras, get_dummy_cameras, store_cameras_to_file

USE_DUMMY_DATA = True  # Set to False to use real scanning

app = Flask(__name__)



@app.route('/cameras', methods=['GET'])
def get_all_cameras():
    return jsonify({
        "cameras": get_dummy_cameras(),  # Changed key from connected_cameras to cameras
        "message": "Cameras retrieved successfully",
        "total_cameras": len(get_dummy_cameras())
    })



def get_camera_by_id(camera_id):
    """
    Retrieves a specific camera by its ID from the dummy cameras list.
    """
    # Iterate through the list to find the matching camera
    for camera in get_dummy_cameras():
        if camera["id"] == camera_id:
            return camera
    return None  # Return None if no matching camera is found


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
        # General exception handler
        return jsonify({
            "error": "Failed to retrieve camera details",
            "message": str(e)
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
            wired_cameras = scan_wired_cameras()
            network_cameras = scan_network_cameras()
            connected_cameras = wired_cameras + network_cameras
        # Store the scanned cameras in a file
        store_cameras_to_file(connected_cameras)

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
        "total_cameras_detected": len(get_dummy_cameras()),
        "last_scan_time": "2025-01-25T15:30:00Z"  # Dummy timestamp for testing
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
