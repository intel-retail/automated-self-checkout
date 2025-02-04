import re
import json
import time
import os
from paho.mqtt.client import Client

# Configuration
current_directory = os.getcwd()
folder_path = os.path.join(
    current_directory, 'performance-tools/benchmark-scripts/results'
)

# Define the pattern for matching log files
pattern = r'^gst-launch_.*_gst\.log$'

# List all matching log files
file_names = os.listdir(folder_path)
matching_files = [file for file in file_names if re.match(pattern, file)]
relative_path = (
    "performance-tools/benchmark-scripts/results/" + matching_files[0]
)
file_path = os.path.join(current_directory, relative_path)

# MQTT Configuration
mqtt_broker = "localhost"
mqtt_port = 1884
mqtt_topic = "grafana/log_data"

# Regex pattern to extract relevant information
data_pattern = (
    r"latency_tracer_pipeline, frame_latency=\(double\)([\d.]+), "
    r"avg=\(double\)([\d.]+), min=\(double\)([\d.]+), max=\(double\)([\d.]+), "
    r"latency=\(double\)([\d.]+), fps=\(double\)([\d.]+), frame_num=\(uint\)(\d+);"
)


def extract_data(file_path):
    """Extract relevant information from the log file."""
    extracted_data = []
    with open(file_path, "r") as file:
        for line in file:
            match = re.search(data_pattern, line)
            if match:
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


def publish_data_to_mqtt(extracted_data):
    """Publish extracted data to MQTT broker."""
    client = Client()
    try:
        client.connect(mqtt_broker, mqtt_port)
        client.loop_start()
        for data in extracted_data:
            payload = json.dumps(data)
            client.publish(mqtt_topic, payload)
            time.sleep(1)
    except Exception as e:
        print(f"Failed to publish to MQTT: {e}")
    finally:
        client.loop_stop()
        client.disconnect()


if __name__ == "__main__":
    extracted_data = extract_data(file_path)
    if extracted_data:
        publish_data_to_mqtt(extracted_data)
    else:
        print("No relevant data found in the log file.")