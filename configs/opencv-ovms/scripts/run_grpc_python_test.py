#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

import unittest
from run_grpc_python import inference

class TestStringMethods(unittest.TestCase):
    def test_inference(self):
        
        self.assertEqual(inference("test"), 'test')

if __name__ == '__main__':
    unittest.main()