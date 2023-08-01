#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

import numpy as np
from tritonclient.utils import *

DataTypeToContentsFieldName = {
    'BOOL' : 'bool_contents',
    'BYTES' : 'bytes_contents',
    'FP32' : 'fp32_contents',
    'FP64' : 'fp64_contents',
    'INT64' : 'int64_contents',
    'INT32' : 'int_contents',
    'UINT64' : 'uint64_contents',
    'UINT32' : 'uint_contents',
    'INT64' : 'int64_contents',
    'INT32' : 'int_contents',
}

def as_numpy(response, name):
    index = 0
    for output in response.outputs:
        if output.name == name:
            shape = []
            for value in output.shape:
                shape.append(value)
            datatype = output.datatype
            field_name = DataTypeToContentsFieldName[datatype]
            contents = getattr(output, "contents")
            contents = getattr(contents, f"{field_name}")
            if index < len(response.raw_output_contents):
                np_array = np.frombuffer(
                    response.raw_output_contents[index], dtype=triton_to_np_dtype(output.datatype))
            elif len(contents) != 0:
                np_array = np.array(contents,
                                    copy=False)
            else:
                np_array = np.empty(0)
            np_array = np_array.reshape(shape)
            return np_array
        else:
            index += 1
    return None

def postProcessMaskRCNN(response, duration):
    # omz instance segmentation model has three outputs
    output1 = as_numpy(response, "3523")
    output2 = as_numpy(response, "3524")
    output3 = as_numpy(response, "masks")
    nu = np.array(output1)
    nu2 = np.array(output2)
    nu3 = np.array(output3)
    # for object classification models show imagenet class
    print('Processing time: {:.2f} ms; fps: {:.2f}'.format(round(np.average(duration), 2),round(1000  / np.average(duration), 2)))
    return output1

def postProcessBit(response, duration):
    output = as_numpy(response, "output_1")
    nu = np.array(output)
    print('Processing time: {:.2f} ms; fps: {:.2f}'.format(round(np.average(duration), 2),round(1000  / np.average(duration), 2)))
    return output

def postProcessYolov5s(response, duration):
    output = as_numpy(response, "326/sink_port_0")
    nu = np.array(output)
    print('Processing time: {:.2f} ms; fps: {:.2f}'.format(round(np.average(duration), 2),round(1000  / np.average(duration), 2)))
    return output