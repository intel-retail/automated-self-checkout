# Dockerfile for RealSenseExtractor

# Use a lightweight Python base image
FROM python:3.9-slim

# Set environment variables to ensure Python runs in non-buffered and UTF-8 mode
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV LANG=C.UTF-8

# Set the working directory inside the container
WORKDIR /app

# Install system dependencies (e.g., for Intel RealSense SDK) and Python dependencies
RUN apt-get update \
    && apt-get install -y libgl1-mesa-glx libglib2.0-0 libusb-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file to leverage Docker's caching
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code to the working directory
COPY . /app/

# Expose any necessary ports (if applicable)
EXPOSE 5000

# Specify the entry point script
CMD ["python", "pollRealSenseSensor.py"]