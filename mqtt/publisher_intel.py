import itertools
import json
from paho.mqtt.client import Client
import time
import os

# MQTT Configuration
BROKER_ADDRESS = "localhost"  # Replace with your MQTT broker address
MQTT_TOPIC = "grafana/log_data"  # Topic to publish the logs
mqtt_port = 1884 # Default MQTT port


# Get the current working directory
current_directory = os.getcwd()

# Define the relative path to the file
relative_path_cpu = 'performance-tools/benchmark-scripts/results/cpu_usage.log'
relative_path_memory = 'performance-tools/benchmark-scripts/results/memory_usage.log'
relative_path_disk = 'performance-tools/benchmark-scripts/results/disk_bandwidth.log'
# Combine the current directory with the relative path
cpu_usage_path = os.path.join(current_directory, relative_path_cpu)
memory_usage_path = os.path.join(current_directory,relative_path_memory)
disk_bandwidth_path = os.path.join(current_directory,relative_path_disk)

# Initialize file handlers
cpu_file = open(cpu_usage_path, 'r')
memory_file = open(memory_usage_path, 'r')
disk_file = open(disk_bandwidth_path, 'r')

# Initialize MQTT client
mqtt_client = Client()
mqtt_client.connect(BROKER_ADDRESS, mqtt_port)

# Function to process a line from the CPU usage file
def process_cpu_line(line):
    parts = line.split()
    if len(parts) == 8 and parts[1] == "all":
        return {"Cpu_user": float(parts[2]), "Cpu_idle": float(parts[7]), "Cpu_iowait": float(parts[4])}
    return None

# Function to process a line from the memory usage file
def process_memory_line(line):
    if line.startswith("Mem:"):
        parts = line.split()
        return {"Memory_total": int(parts[1]), "Memory_used": int(parts[2])}
    return None

# Function to process a line from the disk bandwidth file
def process_disk_line(line):
    total_read = None
    total_write = None

    if line.startswith("Total DISK READ"):
        total_read = line.split('|')[0].split(':')[-1].strip()
        total_write = line.split('|')[1].split(':')[-1].strip()
    elif line.startswith("Current DISK READ"):
        current_read = line.split('|')[0].split(':')[-1].strip()
        current_write = line.split('|')[1].split(':')[-1].strip()
        return {
            
                "total_read": total_read,
                "current_read": current_read,
                "total_write": total_write,
                "current_write": current_write,
            }
        
    return None

# Using itertools.zip_longest to iterate over all files simultaneously
for cpu_line, mem_line, disk_line in itertools.zip_longest(cpu_file, memory_file, disk_file):
    # Process each line
    cpu_data = process_cpu_line(cpu_line) if cpu_line else None
    memory_data = process_memory_line(mem_line) if mem_line else None
    disk_data = process_disk_line(disk_line) if disk_line else None

    # Combine data into a single payload
    log_data = {}
    if cpu_data:
        log_data.update(cpu_data)
    if memory_data:
        log_data.update(memory_data)
    if disk_data:
        log_data.update(disk_data)

    if log_data:
        # Convert to JSON and publish to MQTT
        payload = json.dumps(log_data)
        mqtt_client.publish(MQTT_TOPIC, payload)
        # print(f"Published: {payload}")
    
    # Sleep to simulate real-time log streaming (adjust as needed)
    time.sleep(1)

# Close all file handlers
cpu_file.close()
memory_file.close()
disk_file.close()

# Disconnect MQTT client
mqtt_client.disconnect()
