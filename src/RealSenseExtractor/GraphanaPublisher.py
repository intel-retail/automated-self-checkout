from Publisher import Publisher
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
from datetime import datetime
import json

class GraphanaPublisher(Publisher):
    #Initialising the URL 
    def __init__(self):
        with open('GraphanaConfig.json', 'r') as config_file:
            config = json.load(config_file)

        self.url = config["Graphana"]['url']
        self.token = config["Graphana"]['token']
        self.org = config["Graphana"]['org']
        self.bucket = config["Graphana"]['bucket']
        self.client = InfluxDBClient(url=self.url, token=self.token, org=self.org)
        self.write_api = self.client.write_api(write_options=SYNCHRONOUS)

    def push(self, height, width, depth, timestamp):
        try:
            print("Here I am")
            # Treating the data as a point.
            point = (
                Point("sensor_data")
                .field("height", height)
                .field("width", width)
                .field("depth", depth)
                .time(timestamp)
            )
            print(point)
            
            # Writing into InfluxDB
            self.write_api.write(bucket=self.bucket, org=self.org, record=point)
            print(f"Data written to InfluxDB: Height={height}, Width={width}, Depth={depth}, Timestamp={timestamp}")

        except Exception as e:
            print(f"Failed to push data to InfluxDB: {e}")