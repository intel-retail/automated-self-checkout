# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

import unittest
from main import app, get_camera_by_id
from util import get_dummy_cameras

class TestApp(unittest.TestCase):

    def setUp(self):
        """
        Set up the Flask test client for each test.
        """
        self.app = app.test_client()
        self.app.testing = True  # Enable testing mode

    def test_get_all_cameras(self):
        """
        Test the /cameras endpoint for retrieving all cameras.
        """
        response = self.app.get('/cameras')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn("cameras", data)
        self.assertIn("message", data)
        self.assertIn("total_cameras", data)
        self.assertEqual(len(data["cameras"]), len(get_dummy_cameras()))
        self.assertEqual(data["message"], "Cameras retrieved successfully")

    def test_get_camera_details_success(self):
        """
        Test the /cameras/<camera_id> endpoint for a valid camera ID.
        """
        camera_id = "camera_002"  # Valid dummy camera ID
        response = self.app.get(f'/cameras/{camera_id}')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn("camera", data)
        self.assertEqual(data["camera"]["id"], camera_id)

    def test_get_camera_details_not_found(self):
        """
        Test the /cameras/<camera_id> endpoint for an invalid camera ID.
        """
        camera_id = "camera_999"  # Invalid dummy camera ID
        response = self.app.get(f'/cameras/{camera_id}')
        self.assertEqual(response.status_code, 404)
        data = response.get_json()
        self.assertIn("error", data)
        self.assertIn("message", data)
        self.assertEqual(data["error"], "Camera not found")

    def test_scan_cameras_with_dummy_data(self):
        """
        Test the /scan endpoint using dummy data.
        """
        response = self.app.post('/scan')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn("connected_cameras", data)
        self.assertIn("message", data)
        self.assertIn("total_cameras", data)
        self.assertEqual(len(data["connected_cameras"]), len(get_dummy_cameras()))
        self.assertEqual(data["message"], "Scan completed successfully")

    def test_get_status(self):
        """
        Test the /status endpoint.
        """
        response = self.app.get('/status')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn("status", data)
        self.assertIn("total_cameras_detected", data)
        self.assertIn("last_scan_time", data)
        self.assertEqual(data["status"], "running")
        self.assertEqual(data["total_cameras_detected"], len(get_dummy_cameras()))

    def test_get_camera_by_id(self):
        """
        Test the get_camera_by_id function.
        """
        # Test with valid camera ID
        camera_id = "camera_001"
        camera = get_camera_by_id(camera_id)
        self.assertIsNotNone(camera)
        self.assertEqual(camera["id"], camera_id)

        # Test with invalid camera ID
        camera_id = "camera_999"
        camera = get_camera_by_id(camera_id)
        self.assertIsNone(camera)


if __name__ == '__main__':
    unittest.main()
