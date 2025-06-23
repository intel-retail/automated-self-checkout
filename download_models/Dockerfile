# syntax=docker/dockerfile:1
FROM python:3.10-slim

# Proxy args with defaults to avoid unset variable issues

# Install system dependencies and CA certificates for SSL
RUN apt-get update && \
    apt-get install -y wget curl bash ca-certificates libgl1 libglib2.0-0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Debug: print proxy and environment before installing dependencies
RUN echo "HTTP_PROXY: $HTTP_PROXY" && \
    echo "HTTPS_PROXY: $HTTPS_PROXY" && \
    env

# Set workdir
WORKDIR /workspace

# Copy your scripts and requirements
COPY download_models/requirements.txt /workspace/requirements.txt
COPY download_models/downloadModels.sh /workspace/downloadModels.sh
COPY download_models/download_convert_model.py /workspace/download_convert_model.py

# Make the script executable
RUN chmod +x /workspace/downloadModels.sh


# Install Python dependencies with verbose output for logs
RUN pip3 install --upgrade pip -vvv --no-cache-dir && \
    pip3 install -vvv --no-cache-dir -r /workspace/requirements.txt


# Default command (can be overridden)
CMD ["/bin/bash", "-c", "/workspace/downloadModels.sh"]
