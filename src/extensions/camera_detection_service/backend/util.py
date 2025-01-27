import pyudev
import subprocess
import json
import os
import cv2
os.environ["OPENCV_AVFOUNDATION_SKIP_AUTH"] = "1"
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
        "index": 1,  # Add this field
        "status": "active",
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

def get_dummy_cameras():
    """
    Returns dummy data for connected cameras as a list.
    """
    return list(dummy_cameras.values())



def scan_wired_cameras(start_index=1):
    """
    Scans the system for wired cameras using OpenCV and retrieves basic camera information.
    Args:
        start_index (int): The starting index for camera numbering.
    Returns:
        list: A list of wired camera information.
        int: The next available index after processing wired cameras.
    """
    cameras = []

    # Iterate over a range of possible camera indices
    for camera_index in range(10):  # Check the first 10 indices (adjust as needed)
        cap = cv2.VideoCapture(camera_index)
        if cap.isOpened():
            # Fetch basic details about the camera
            camera_name = f"Camera {camera_index}"
            resolution = f"{int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))}x{int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))}"
            fps = int(cap.get(cv2.CAP_PROP_FPS))

            cameras.append({
                "id": f"camera_{start_index}",
                "type": "wired",
                "connection": "integrated",  # Assuming USB as the default for OpenCV
                "index": start_index,
                "status": "active",
                "name": camera_name,
                "resolution": resolution,
                "fps": fps,
                "ip": None,  # Wired cameras don't have IP
                "port": None,  # Wired cameras don't have a port
            })
            start_index += 1  # Increment the shared index
            cap.release()

    return cameras, start_index


def scan_network_cameras(start_index):
    """
    Scans the network for wireless cameras using Nmap.
    Args:
        start_index (int): The starting index for camera numbering.
    Returns:
        list: A list of network camera information.
        int: The next available index after processing network cameras.
    """
    cameras = []
    try:
        # Run Nmap to scan for common camera ports (e.g., RTSP: 554, HTTP: 80)
        result = subprocess.run(
            ["nmap", "-T5", "-p", "554,80", "-oG", "-", "192.168.0.0/24"],  # Replace with your subnet
            capture_output=True,
            text=True,
        )
        output = result.stdout

        # Parse Nmap output for active cameras
        for line in output.split("\n"):
            if "open" in line:
                parts = line.split()
                ip = parts[1]
                cameras.append({
                    "id": f"camera_{start_index}",
                    "type": "wireless",
                    "connection": "Wi-Fi",
                    "index": start_index,
                    "status": "active",
                    "index":13,
                    "name": "Unknown Network Camera",
                    "resolution": "Unknown",
                    "fps": None,
                    "ip": ip,
                    "port": 554 if "554/open" in line else 80,
                })
                start_index += 1  # Increment the shared index
    except Exception as e:
        print(f"Error scanning network: {e}")

    return cameras, start_index

def store_cameras_to_file(cameras, file_name="scanned_cameras.txt"):
    """
    Stores the camera data in a text file in the specified format.
    
    Args:
        cameras (list): List of camera dictionaries.
        file_name (str): Name of the file to store the data. Default is 'scanned_cameras.txt'.
    """
    # Convert the list of cameras into a dictionary with keys like "camera_001"
    cameras_dict = {f"camera_{str(i+1).zfill(3)}": cam for i, cam in enumerate(cameras)}
    
    # Write the cameras to the file in the desired format
    with open(file_name, "w") as file:
        file.write("actual_cameras = {\n")
        for key, camera in cameras_dict.items():
            file.write(f'    "{key}": {json.dumps(camera, indent=4)},\n')
        file.write("}\n")

def read_actual_cameras(file_path):
    """
    Reads a file containing a Python dictionary (with assignment) and parses it into a Python object.

    Args:
        file_path (str): Path to the .txt file.

    Returns:
        dict: A dictionary representation of the cameras data.
    """
    with open(file_path, "r") as file:
        content = file.read()

    # Replace `null` with `None` to make it compatible with Python
    content = content.replace("null", "None")

    # Extract the dictionary part after `actual_cameras =`
    content = content.split("=", 1)[1].strip()

    # Safely evaluate the content into a Python dictionary
    actual_cameras = eval(content)

    return actual_cameras



