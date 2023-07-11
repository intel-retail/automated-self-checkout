#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

import sys
sys.path.append("/model_server/demos/common/python")

import argparse
import datetime
import cv2
import grpc
from client_utils import print_statistics
from tritonclient.grpc import service_pb2, service_pb2_grpc
from grpc_postprocess import *

def openInputSrc(input_src):
    # OpenCV RTSP Stream
    stream = cv2.VideoCapture(input_src)
    if not stream.isOpened():
        print('Unable to open source:' + input_src)
        exit(-1)
    return stream

def setupGRPC(address, port):
    address = "{}:{}".format(address, port)
    # Create gRPC stub for communicating with the server
    channel = grpc.insecure_channel(address)
    grpc_stub = service_pb2_grpc.GRPCInferenceServiceStub(channel)
    return grpc_stub

def getModelSize(model_name):
    return [608,608]

def inference(img_str, model_name, grpc_stub):
    inputs = []
    inputs.append(service_pb2.ModelInferRequest().InferInputTensor())
    inputs[0].name = "image"
    inputs[0].datatype = "BYTES"
    inputs[0].shape.extend([1])
    inputs[0].contents.bytes_contents.append(img_str)
    outputs = []
    outputs.append(service_pb2.ModelInferRequest().InferRequestedOutputTensor())
    outputs[0].name = "mask"
    request = service_pb2.ModelInferRequest()
    request.model_name = model_name
    request.inputs.extend(inputs)
    start_time = datetime.datetime.now()
    request.outputs.extend(outputs)
    response = grpc_stub.ModelInfer(request)
    end_time = datetime.datetime.now()
    duration = (end_time - start_time).total_seconds() * 1000
    return [response, duration]

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Sends requests via KServe gRPC API using images in format supported by OpenCV. It displays performance statistics and optionally the model accuracy')
    parser.add_argument('--input_src', required=True, default='', help='input source for the inference pipeline')
    parser.add_argument('--grpc_address',required=False, default='localhost',  help='Specify url to grpc service. default:localhost')
    parser.add_argument('--grpc_port',required=False, default=9000, help='Specify port to grpc service. default: 9000')
    parser.add_argument('--model_name', default='instance-segmentation-security-1040', help='Define model name, must be same as is in service. default: resnet',
                        dest='model_name')
    args = vars(parser.parse_args())

    # print("Connect to stream")
    stream = openInputSrc(args['input_src'])

    # print("Establish OVMS GRPc connection")
    grpc_stub = setupGRPC(args['grpc_address'],args['grpc_port'])

    # print("Get the model size from OVMS metadata")
    model_size = getModelSize(args['model_name'])

    # print("Begin inference loop")
    while True:
        try:
            # get frame from OpenCV
            _, frame = stream.read()
            img = cv2.resize(frame, (model_size[0], model_size[1]))
            img_str = cv2.imencode('.jpg', img)[1].tobytes()

            response = inference(img_str, args['model_name'], grpc_stub)
            postProcessMaskRCNN(response[0], response[1])
        except Exception:
            pass