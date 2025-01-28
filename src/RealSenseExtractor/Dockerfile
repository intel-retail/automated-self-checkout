# Use a lightweight Python base image
FROM python:3.9-slim

# Set environment variables to ensure Python runs in non-buffered and UTF-8 mode
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV LANG=C.UTF-8

# Set the working directory inside the container
WORKDIR /app

# Install system dependencies (e.g., for Intel RealSense SDK) and Python dependencies
RUN apt-get update 
RUN apt-get install -y libgl1-mesa-glx
RUN apt-get install -y libglib2.0-0
RUN apt-get install -y libusb-1.0-0

# Copy the requirements file to leverage Docker's caching
COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code to the working directory
COPY . /app/

# Expose any necessary ports (if applicable)
# EXPOSE 5000

# Specify the entry point script (change to the correct script name for RealSenseExtractor)
CMD ["python", "pollRealSenseSensor.py"]
