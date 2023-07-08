#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

import unittest
from run_grpc_python import *

class TestOpenInputSrc(unittest.TestCase):
    def test_inference(self):
        self.assertEqual(openInputSrc("inference"), 'inference')

class TestSetupGRPC(unittest.TestCase):
    def test_inference(self):
        self.assertEqual(setupGRPC("localhost", "9000"), 'localhost:9000')

class TestGetModelSize(unittest.TestCase):
    def test_inference(self):
        self.assertEqual(getModelSize("model_name"), [608,608])

class TestInference(unittest.TestCase):
    def test_inference(self):
        self.assertEqual(inference("test"), 'test')

class TestAsNumpy(unittest.TestCase):
    def test_inference(self):
        self.assertEqual(as_numpy("response","name"), None)

if __name__ == '__main__':
    unittest.main()