from Publisher import Publisher
import requests
import logging
import json
import os

class MicroServicePublisher(Publisher):
    def __init__(self, config_file='RealSenseConfig.json'):
        self.config = self._load_config(config_file)
        
        microservice_config = self.config.get('microservice', {})
        self.microservice_url = microservice_config.get('url', 'https://intel.com/metrics')
        self.headers = microservice_config.get('headers', {'Content-Type':'application/json'})
        
        logging.basicConfig(level=logging.INFO)
        
    def _load_config(self, config_file):
        if not os.path.exists(config_file):
            logging.error(f"Configuration file {config_file} does not exist.")
            return {}
        try:
            with open(config_file, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            logging.error(f"Error extracting JSON from {config_file}: {e}")
            return {}
    
    def push(self, height, width, depth, timestamp):
        data = {
            "height":height,
            "width":width,
            "depth":depth,
            "timestamp":str(timestamp)
        }
                
        try:
            response = requests.post(self.microservice_url, json=data, headers=self.headers, timeout=10)
            if response.status_code == 200:
                logging.info("Data pushed successfully: %s", response.json())
            else:
                logging.error("Failed to push data. Status code: %d, Respnse: %s", response.status_code, response.text)
        except requests.RequestException as e:
            logging.error("An error occurred while pushing data with following error: %s", e)
            