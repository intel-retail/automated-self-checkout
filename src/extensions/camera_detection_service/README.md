```
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#
```

# Camera Detection Service

A Python application that detects connected cameras (USB/integrated) and provides real-time previews with cross-platform support (Windows/WSL/Linux).

## Features
- Automatic camera detection (USB and integrated)
- Cross-platform support (Windows & WSL/Linux)
- Live camera preview with GUI interface
- Real-time monitoring for new devices
- Interactive camera selection list
- Automatic resource cleanup

## Prerequisites
- Python 3.6 or higher
- Virtual environment recommended

## Installation
### 1. Clone Repository
```bash
git clone https://github.com/intel-retail/automated-self-checkout.git
cd src/extensions/camera_detection_service
```

### 2. Create Virtual Environment [Optional]
```bash
python -m venv venv
```

### 3. Activate Virtual Environment
**Windows:**
```cmd
venv\Scripts\activate
```

**Linux/WSL:**
```bash
source venv/bin/activate
```

### 4. Install Dependencies
```bash
pip install -r requirements.txt 
```

## Usage

### [Option 1] Makefile Instructions

1. **Navigate to the project directory**
   ```bash
   cd /src/extensions/camera_detection_service
   ```
   *(This is where the `Makefile` is located.)*

2. **Restart the service**
   ```bash
   make install
   make stop && make run
   ```
   *(Wait for the frontend to load.)*

3. **Start the camera scan**
   - Click the **"Scan Now"** button on the right.
   - Wait a few seconds until you see **"Scan completed successfully"**.
   - Press **OK** to continue.

4. **Select a camera**
   - Click on a camera in the **left panel**.
   - The **preview** should appear.

### [Option 2] Running the Application with launch.py
```bash
python launch.py
```

**Windows Users:**  
The application will automatically detect DirectShow compatible cameras.

**WSL Users:**  
Ensure:
- WSLg is enabled (Windows 11 recommended)
- Cameras are properly passed through to WSL
- Required dependencies:
  ```bash
  sudo apt install libgl1-mesa-glx nmap
  ```

### Application Interface
1. Detected cameras appear in the left panel
2. Select any camera to view preview
3. Application automatically updates when new cameras are connected
4. Preview maintains aspect ratio and centers in window
5. Close window to exit application

## Troubleshooting

### No Cameras Detected
**WSL:**
```bash
# Check video devices
ls /dev/video*
# Ensure proper permissions
sudo chmod 666 /dev/video*
```

**Windows:**
- Update camera drivers
- Verify camera works in other applications

### Preview Issues
- Try different camera indexes
- Check OpenCV compatibility with your camera

### Virtual Environment Issues
```bash
# If getting externally-managed error
python -m venv --system-site-packages venv
```
