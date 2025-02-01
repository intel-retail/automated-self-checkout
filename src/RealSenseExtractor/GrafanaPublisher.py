# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

from Publisher import Publisher
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
from datetime import datetime
import json

class GrafanaPublisher(Publisher):
    # Initializing the URL and InfluxDB client
    def __init__(self):
        with open('RealSenseConfig.json', 'r') as config_file:
            config = json.load(config_file)

        self.url = config["Grafana"]["url"]
        self.token = config["Grafana"]["token"]
        self.org = config["Grafana"]["org"]
        self.bucket = config["Grafana"]["bucket"]

        self.client = InfluxDBClient(url=self.url, token=self.token, org=self.org)
        self.write_api = self.client.write_api(write_options=SYNCHRONOUS)
        self.buckets_api = self.client.buckets_api()

        self.ensure_bucket_exists()

    def ensure_bucket_exists(self):
        try:
            bucket_exists = any(b.name == self.bucket for b in self.buckets_api.find_buckets().buckets)
            if not bucket_exists:
                self.buckets_api.create_bucket(bucket_name=self.bucket, org=self.org)
                print(f"Bucket '{self.bucket}' created successfully.")
            else:
                print(f"Bucket '{self.bucket}' already exists.")
        except Exception as e:
            print(f"Failed to verify or create bucket: {e}")

    def push(self, height, width, depth, timestamp=None):
        try:
            if timestamp is None:
                timestamp = datetime.now()

            # Treating the data as a point
            point = (
                Point("sensor_data")
                .field("height", height)
                .field("width", width)
                .field("depth", depth)
                .time(timestamp)
            )

            # Writing into InfluxDB
            self.write_api.write(bucket=self.bucket, org=self.org, record=point)
            print(f"Data written to InfluxDB: Height={height}, Width={width}, Depth={depth}, Timestamp={timestamp}")

        except Exception as e:
            print(f"Failed to push data to InfluxDB: {e}")

    def close(self):
        self.client.close()
        print("InfluxDB client connection closed.")

