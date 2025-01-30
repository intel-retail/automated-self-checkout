# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

import os
import sys
import subprocess
import time
import signal
import platform
import select

# Configuration
SERVICE_DIR = os.path.join('src', 'extensions', 'camera_detection_service')
VENV_NAME = 'venv'
REQUIREMENTS_FILE = 'requirements.txt'

def get_venv_python():
    """Get path to virtual environment Python executable"""
    if platform.system() == 'Windows':
        return os.path.join(SERVICE_DIR, VENV_NAME, 'Scripts', 'python.exe')
    else:
        return os.path.join(SERVICE_DIR, VENV_NAME, 'bin', 'python')

def setup_environment():
    """Create virtual environment and install requirements if missing"""
    venv_path = os.path.join(SERVICE_DIR, VENV_NAME)
    requirements_path = os.path.join(SERVICE_DIR, REQUIREMENTS_FILE)

    # Create virtual environment if missing
    if not os.path.exists(venv_path):
        print(f"Creating virtual environment in {venv_path}...")
        try:
            subprocess.run([
                sys.executable,
                '-m', 'venv',
                venv_path
            ], check=True)
            print("Virtual environment created successfully")
        except subprocess.CalledProcessError as e:
            print(f"Failed to create virtual environment: {str(e)}")
            sys.exit(1)

    # Install requirements if file exists
    if os.path.exists(requirements_path):
        print("Installing requirements...")
        pip_exec = [
            get_venv_python(),
            '-m', 'pip',
            'install',
            '-r', requirements_path
        ]
        
        try:
            subprocess.run(pip_exec, check=True)
            print("Requirements installed successfully")
        except subprocess.CalledProcessError as e:
            print(f"Failed to install requirements: {str(e)}")
            sys.exit(1)
    else:
        print(f"Warning: No {REQUIREMENTS_FILE} found in {SERVICE_DIR}")

def run_services():
    """Main function to run the services"""
    backend_port = 8080
    venv_python = get_venv_python()

    # Path validation
    backend_path = os.path.join(SERVICE_DIR, 'backend', 'main.py')
    frontend_path = os.path.join(SERVICE_DIR, 'frontend', 'front.py')

    if not all(os.path.exists(p) for p in [backend_path, frontend_path]):
        print("Error: Could not find service files")
        sys.exit(1)

    # Check port availability
    def is_port_in_use(port):
        # Implementation from previous version
        pass

    if is_port_in_use(backend_port):
        print(f"Port {backend_port} is already in use!")
        sys.exit(1)

    # Start backend
    backend_cmd = [
        venv_python,
        backend_path,
        '--port', str(backend_port)
    ]
    
    backend_proc = subprocess.Popen(
        backend_cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        universal_newlines=True,
        env={**os.environ, "PYTHONUNBUFFERED": "1"}  # Ensure unbuffered output
    )

    # Wait for backend initialization
    print("Starting backend service...")
    time.sleep(2)
    
    # Start frontend
    frontend_proc = subprocess.Popen(
        [venv_python, frontend_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        universal_newlines=True,
        env={**os.environ, "PYTHONUNBUFFERED": "1"}
    )

    # Signal handling
    def signal_handler(sig, frame):
        print("\nTerminating services...")
        backend_proc.terminate()
        frontend_proc.terminate()
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)

    # Monitor output from both processes
    print("Services running. Press Ctrl+C to terminate\n")

    streams = [backend_proc.stdout, frontend_proc.stdout]
    while True:
        readable, _, _ = select.select(streams, [], [])
        for stream in readable:
            line = stream.readline()
            if not line:
                streams.remove(stream)
                continue
            if stream is backend_proc.stdout:
                print(f"[Backend] {line.strip()}")
            else:
                print(f"[Frontend] {line.strip()}")
        if not streams:
            break

if __name__ == '__main__':
    # First setup environment
    setup_environment()
    
    # Then run services
    run_services()