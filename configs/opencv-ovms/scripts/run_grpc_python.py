#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#
import sys
import argparse

def inference(input_src):
    print(input_src)
    return input_src

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Sends requests via KServe gRPC API using images in format supported by OpenCV. It displays performance statistics and optionally the model accuracy')
    parser.add_argument('--input_src', required=True, default='', help='input source for the inference pipeline')
    args = vars(parser.parse_args())

    inference(args.get('input_src'))
