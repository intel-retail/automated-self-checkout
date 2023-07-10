#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

import unittest
from grpc_python import *

class TestOpenInputSrc(unittest.TestCase):
    def test_inference(self):
        self.assertTrue(openInputSrc("rtsp://127.0.0.1:8554/camera_0"))

class TestSetupGRPC(unittest.TestCase):
    def test_inference(self):
        self.assertTrue(setupGRPC("127.0.0.1", "9000"))

class TestGetModelSize(unittest.TestCase):
    def test_inference(self):
        self.assertEqual(getModelSize("model_name"), [608,608])

class TestInference(unittest.TestCase):
    def test_inference(self):
        # Get model size
        model_size = getModelSize("instance-segmentation-security-1040")
        # Get video stream
        stream = openInputSrc("rtsp://127.0.0.1:8554/camera_0")
        # Get frame from OpenCV
        _, frame = stream.read()
        img = cv2.resize(frame, (model_size[0], model_size[1]))
        img_str = cv2.imencode('.jpg', img)[1].tobytes()
        # Get GRPc
        grpc_stub = setupGRPC("127.0.0.1", "9000")
        response = inference(img_str,"instance-segmentation-security-1040", grpc_stub)
        self.assertTrue(response)

class TestAsNumpy(unittest.TestCase):
    def test_inference(self):
                # Get model size
        model_size = getModelSize("instance-segmentation-security-1040")
        # Get video stream
        stream = openInputSrc("rtsp://127.0.0.1:8554/camera_0")
        # Get frame from OpenCV
        _, frame = stream.read()
        img = cv2.resize(frame, (model_size[0], model_size[1]))
        img_str = cv2.imencode('.jpg', img)[1].tobytes()
        # Get GRPc
        grpc_stub = setupGRPC("127.0.0.1", "9000")
        response = inference(img_str,"instance-segmentation-security-1040", grpc_stub)
        results = as_numpy(response[0], "3523")
        self.assertTrue(len(results))

class TestPostProcessMaskRCNN(unittest.TestCase):
    def test_inference(self):
                # Get model size
        model_size = getModelSize("instance-segmentation-security-1040")
        # Get video stream
        stream = openInputSrc("rtsp://127.0.0.1:8554/camera_0")
        # Get frame from OpenCV
        _, frame = stream.read()
        img = cv2.resize(frame, (model_size[0], model_size[1]))
        img_str = cv2.imencode('.jpg', img)[1].tobytes()
        # Get GRPc
        grpc_stub = setupGRPC("127.0.0.1", "9000")
        response = inference(img_str,"instance-segmentation-security-1040", grpc_stub)
        results = postProcessMaskRCNN(response[0], response[1])
        self.assertTrue(len(results))

# TODO: implement the bit process
# class TestPostProcessBit(unittest.TestCase):
#     def test_inference(self):
#                 # Get model size
#         model_size = getModelSize("instance-segmentation-security-1040")
#         # Get video stream
#         stream = openInputSrc("rtsp://127.0.0.1:8554/camera_0")
#         # Get frame from OpenCV
#         _, frame = stream.read()
#         img = cv2.resize(frame, (model_size[0], model_size[1]))
#         img_str = cv2.imencode('.jpg', img)[1].tobytes()
#         # Get GRPc
#         grpc_stub = setupGRPC("127.0.0.1", "9000")
#         response = inference(img_str,"instance-segmentation-security-1040", grpc_stub)
#         results = postProcessBit(response[0], response[1])
#         self.assertTrue(len(results))

if __name__ == '__main__':
    unittest.main()