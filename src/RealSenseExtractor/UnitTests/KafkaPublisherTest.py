import unittest
from unittest.mock import patch, MagicMock
from KafkaPublisher import KafkaPublisher

class TestKafkaPublisher(unittest.TestCase):

    def setUp(self):

        self.kafka_core_mock = MagicMock()

        patcher = patch('KafkaPublisher.KafkaCore', return_value=self.kafka_core_mock)
        self.addCleanup(patcher.stop)
        self.mock_kafka_core_class = patcher.start()
    
        self.publisher = KafkaPublisher()

    def test_push_calls_produce_message(self):
    
        height = 480
        width = 640
        depth = 0.5
        timestamp = 1674933540000000000

        self.publisher.push(height, width, depth, timestamp)

        expected_message = {
            'height': height,
            'width': width,
            'depth': depth,
            'timestamp': str(timestamp)
        }

        # Assert produce_message was called with the correct message
        self.kafka_core_mock.produce_message.assert_called_once_with(message=expected_message)

if __name__ == "__main__":
    unittest.main()
