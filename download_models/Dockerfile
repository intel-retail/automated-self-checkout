# syntax=docker/dockerfile:1
FROM python:3.10-slim


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
COPY download_models/downloadAndQuantizeModel.sh /workspace/downloadAndQuantizeModel.sh
COPY download_models/efnetv2b0_download_quantize.py /workspace/efnetv2b0_download_quantize.py

# Make the script executable
RUN chmod +x /workspace/downloadModels.sh
RUN chmod +x /workspace/downloadAndQuantizeModel.sh


# Install Python dependencies with verbose output for logs
RUN pip3 install --upgrade pip -v --no-cache-dir && \
    pip3 install -v --no-cache-dir -r /workspace/requirements.txt


# Default command
CMD ["/bin/bash", "-c", "\
    python3 efnetv2b0_download_quantize.py && \
    chmod -R 755 /workspace/models && \
    /workspace/downloadModels.sh"]
