# syntax=docker/dockerfile:1
FROM ubuntu:24.04

# Install system dependencies
RUN apt-get update && \
    apt-get install -y python3.11 python3.11-venv python3.11-distutils python3-pip git wget libffi-dev && \
    ln -sf /usr/bin/python3.11 /usr/bin/python3 && \
    python3 -m pip install --upgrade pip

# Set workdir
WORKDIR /workspace

# Copy your scripts and requirements
COPY download_models/requirements.txt /workspace/requirements.txt
COPY download_models/downloadModels.sh /workspace/downloadModels.sh
COPY download_models/download_convert_model.py /workspace/download_convert_model.py

# Make the script executable
RUN chmod +x /workspace/downloadModels.sh

# Install Python dependencies
RUN python3 -m pip install -r requirements.txt

# Default command (can be overridden)
CMD ["/bin/bash"]
