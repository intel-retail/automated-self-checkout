import pyudev
import subprocess
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

def scan_wired_cameras():
    """
    Scans the system for wired cameras connected via USB or HDMI.
    """
    context = pyudev.Context()
    cameras = []

    for device in context.list_devices(subsystem="video4linux"):
        cameras.append({
            "id": device.sys_name,  # Device name like 'video0'
            "type": "wired",
            "connection": "USB" if "usb" in device.device_path else "HDMI",
            "status": "active",
            "name": device.get("ID_MODEL", "Unknown Camera"),
            "resolution": "Unknown",  # Resolution might need additional libraries to fetch
            "fps": None,
            "ip": None,
            "port": None,
        })

    return cameras


def scan_network_cameras():
    """
    Scans the network for wireless cameras using Nmap.
    """
    cameras = []
    try:
        # Run Nmap to scan for common camera ports (e.g., RTSP: 554, HTTP: 80)
        result = subprocess.run(
            ["nmap", "-p", "554,80", "-oG", "-", "192.168.1.0/24"],  # Replace with your subnet
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
                    "id": f"camera_{len(cameras) + 1}",
                    "type": "wireless",
                    "connection": "Wi-Fi",
                    "status": "active",
                    "name": "Unknown Network Camera",
                    "resolution": "Unknown",
                    "fps": None,
                    "ip": ip,
                    "port": 554 if "554/open" in line else 80,
                })
    except Exception as e:
        print(f"Error scanning network: {e}")

    return cameras
import json

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
        file.write("dummy_cameras = {\n")
        for key, camera in cameras_dict.items():
            file.write(f'    "{key}": {json.dumps(camera, indent=4)},\n')
        file.write("}\n")
