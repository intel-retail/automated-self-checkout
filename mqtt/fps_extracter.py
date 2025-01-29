import re
import json
import time
from paho.mqtt.client import Client
import os


# Configuration

current_directory = os.getcwd()
# Define the path to the folder
folder_path = os.path.join(current_directory, 'performance-tools/benchmark-scripts/results')

# Define the pattern for matching file names
pattern = r'^gst-launch_.*_gst\.log$'

# List all files in the directory
file_names = os.listdir(folder_path)

# Filter files using the regular expression pattern
matching_files = [file for file in file_names if re.match(pattern, file)]
relative_path = "performance-tools/benchmark-scripts/results/" + matching_files[0]
file_path = os.path.join(current_directory, relative_path)
# print(file_path)

mqtt_broker = "localhost"  # Replace with your broker address
mqtt_port = 1884  # Default MQTT port
mqtt_topic = "grafana/log_data"  # Replace with your topic

# Regex pattern to extract relevant information
data_pattern = r"latency_tracer_pipeline, frame_latency=\(double\)([\d.]+), avg=\(double\)([\d.]+), min=\(double\)([\d.]+), max=\(double\)([\d.]+), latency=\(double\)([\d.]+), fps=\(double\)([\d.]+), frame_num=\(uint\)(\d+);"

# Extract relevant information from the log file
def extract_data(file_path):
    extracted_data = []
    with open(file_path, "r") as file:
        for line in file:
            match = re.search(data_pattern, line)
            if match:
                # Create a key-value pair dictionary for each match
                data = {
                    "frame_latency": float(match.group(1)),
                    "avg": float(match.group(2)),
                    "min": float(match.group(3)),
                    "max": float(match.group(4)),
                    "latency": float(match.group(5)),
                    "fps": float(match.group(6)),
                    "frame_num": int(match.group(7))
                }
                extracted_data.append(data)
    return extracted_data

# Publish data to MQTT
def publish_data_to_mqtt(extracted_data):
    client = Client()

    try:
        # Connect to the MQTT broker
        client.connect(mqtt_broker, mqtt_port)
        client.loop_start()

        # Publish each data record
        for data in extracted_data:
            payload = json.dumps(data)  # Convert dictionary to JSON string
            client.publish(mqtt_topic, payload)
            # print(f"Published data: {payload} to topic {mqtt_topic}")
            time.sleep(1)  # Simulate data streaming interval

    except Exception as e:
        print(f"Failed to publish to MQTT: {e}")
    finally:
        client.loop_stop()
        client.disconnect()

# Main function
if __name__ == "__main__":
    # Extract data from the log file
    extracted_data = extract_data(file_path)
    if extracted_data:
        # print("Extracted data:", extracted_data)
        # Publish extracted data to MQTT
        publish_data_to_mqtt(extracted_data)
    else:
        print("No relevant data found in the log file.")
