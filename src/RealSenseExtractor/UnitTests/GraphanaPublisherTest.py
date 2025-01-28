import unittest
from unittest.mock import patch, MagicMock
from datetime import datetime
import json
from GraphanaPublisher import GraphanaPublisher

class TestGraphanaPublisher(unittest.TestCase):
    def setUp(self):
        self.mock_config = {
            "Graphana": {
                "url": "http://localhost:8086",
                "token": "test_token",
                "org": "test_org",
                "bucket": "test_bucket"
            }
        }

        patcher = patch("builtins.open", unittest.mock.mock_open(read_data=json.dumps(self.mock_config)))
        self.addCleanup(patcher.stop)
        patcher.start()

        self.mock_client = MagicMock()
        self.mock_write_api = MagicMock()
        self.mock_client.write_api.return_value = self.mock_write_api

        client_patcher = patch("GraphanaPublisher.InfluxDBClient", return_value=self.mock_client)
        self.addCleanup(client_patcher.stop)
        client_patcher.start()

        self.publisher = GraphanaPublisher()

    def test_push_success(self):
        
        height = 480
        width = 640
        depth = 0.5
        timestamp = datetime.utcnow().isoformat()

        self.publisher.push(height, width, depth, timestamp)

        self.mock_write_api.write.assert_called_once()

    def test_push_failure(self):
        
        height = 480
        width = 640
        depth = 0.5
        timestamp = datetime.utcnow().isoformat()

        self.mock_write_api.write.side_effect = Exception("Mock write error")

        try:
            self.publisher.push(height, width, depth, timestamp)
        except Exception:
            self.fail("push() raised an exception unexpectedly!")

        self.mock_write_api.write.assert_called_once()


if __name__ == "__main__":
    unittest.main()
