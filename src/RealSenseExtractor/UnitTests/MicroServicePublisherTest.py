# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

import unittest
from unittest.mock import patch
from MicroServicePublisher import MicroServicePublisher

class TestMicroServicePublisher(unittest.TestCase):
    
    @patch("requests.post")
    @patch("logging.info")
    def test_push_success(self, mock_logging_info, mock_post):
    
        mock_post.return_value.status_code = 200
        mock_post.return_value.json.return_value = {"message": "success"}

        publisher = MicroServicePublisher()
        publisher.microservice_url = "https://example.com/metrics"
        publisher.headers = {"Content-Type": "application/json"}

        height, width, depth, timestamp = 480, 640, 0.5, "2025-01-27T23:10:04Z"

        publisher.push(height, width, depth, timestamp)

        mock_post.assert_called_once_with(
            "https://example.com/metrics",
            json={
                "height": height,
                "width": width,
                "depth": depth,
                "timestamp": timestamp,
            },
            headers={"Content-Type": "application/json"},
            timeout=10,
        )

        mock_logging_info.assert_called_once_with(
            "Data pushed successfully: %s", {"message": "success"}
        )


if __name__ == '__main__':
    unittest.main()
