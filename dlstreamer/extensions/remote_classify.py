'''
* Copyright (C) 2023 Intel Corporation.
*
* SPDX-License-Identifier: Apache-2.0
'''

import cv2
import ovmsclient
import numpy 
import json
import threading
import time
import os
from multiprocessing import Process, Queue
from vaserving.common.utils import logging

def softmax(logits, axis=None):
    exp = numpy.exp(logits)
    return exp / numpy.sum(exp, axis=axis)

def process_result(region, result, model_name, labels=None):
    result = softmax(result)
    classification = numpy.argmax(result)
    if region:
        tensor = region.add_tensor("classification")
        tensor["label_id"] = int(classification)
        tensor["model_name"] = model_name
        tensor["confidence"] = float(result[0][int(classification)])
        if labels:
            tensor["label"] = labels[tensor["label_id"]]
        else:
            tensor["label"] = str(tensor["label_id"])
        
class OVMSClassify:

    def _process(self):
        pid = os.getpid()
        
        try:
            client = ovmsclient.make_grpc_client(self._model_server)
        except Exception as error:
            print("Can't connect to model server %s, %s"%(self._model_server,error))
            return
        self._logger.info("{} Process: {} Connected to ovms-server: {}".format(self._stream,
                                                                                pid,
                                                                                self._model_server))
        try:

            while True:
                image = self._input_queue.get()
                if not image:
                    break
                
                result = client.predict(inputs={self._input_name:image[1]},model_name = self._model_name)
                self._output_queue.put((image[0],result,image[2],time.time(),pid))
        except Exception as error:
            print("Exception in request: %s" %(error))

        self._output_queue.put((None,None,None,None,None))

        del client
        
        self._logger.info("{} Process: {} Completed".format(self._stream,pid))
        

    def __del__(self):
        for _ in self._processes:
            self._input_queue.put(None)
            
    def __init__(self,
                 model_name="efficientnet-b0",
                 model_proc="/home/pipeline-server/models/efficientnet-b0/1/efficientnet-b0.json",
                 model_server="ovms-server:9000",
                 processes=16,
                 max_objects=None,
                 min_objects=None,
                 stream=None,
                 scale=True,
                 object_filter=[]):
        self._model_server = model_server
        self._model_name = model_name
        self._input_queue = Queue()
        self._output_queue = Queue()
        self._labels = []
        self._start_time =time.time()
        self._last_report_time = self._start_time
        self._classify_count = 0
        self._latencies = 0
        self._frames = 0
        self._min_objects = min_objects
        self._max_objects = max_objects
        self._logger = logging.get_logger('remote-classify', is_static=True)
        self._stream = stream
        self._region_sizes = 0
        self._scale = scale
        self._object_filter = object_filter

        if not stream:
            self._stream = ""

        if model_proc:
            with open(model_proc, 'r') as model_proc_file:
                model_proc_data = json.load(model_proc_file)
            self._labels = model_proc_data["output_postproc"][0]["labels"]
            self._input_name = model_proc_data["input_preproc"][0]["layer_name"]

        self._processes = []

        for _ in range(processes):
            self._processes.append(Process(target=self._process,daemon=True))
            self._processes[-1].start()
        
    def process_frame(self, frame):
        regions = list(frame.regions())
        if self._object_filter:
            regions = [region for region in regions if region.label() in self._object_filter]

        if self._min_objects and len(regions) < self._min_objects:
            for _ in range(len(regions),self._min_objects):
                regions.append(frame.add_region(0,0,1,1,"fake",1.0,True))

        if self._max_objects and len(regions)>self._max_objects:
            regions=regions[0:self._max_objects]

        with frame.data() as frame_data:
            for index, region in enumerate(regions):
                if self._max_objects and index>self._max_objects:
                    break
                region_rect = region.rect()
                region_data = frame_data[
                    region_rect.y:region_rect.y+region_rect.h,
                    region_rect.x:region_rect.x+region_rect.w
                ]
                if self._scale:
                    region_data = cv2.resize(region_data,(224,224))
                _,img = cv2.imencode(".jpeg",region_data)
                self._region_sizes += len(img)
                self._input_queue.put((index,bytes(img),time.time()))

        for i in range(len(regions)):
            if self._max_objects and i>self._max_objects:
                break
            index,result,input_time,output_time,pid = self._output_queue.get()
            if index is None:
                raise Exception("Error sending request to model server")
            self._latencies += output_time - input_time
            process_result(regions[index],
                           result,
                           self._model_name,
                           self._labels)

        self._classify_count += len(regions)
        self._frames += 1

        if time.time()-self._last_report_time>1 and self._classify_count:
            self._last_report_time=time.time()
            self._logger.info("{} Classification IPS: {}, Average Latency: {}, Objects Per Frame: {}, Average Region Size: {}" .format
                  (self._stream,
                   self._classify_count/(self._last_report_time-self._start_time),
                   self._latencies / self._classify_count,
                   self._classify_count/self._frames,
                   self._region_sizes/self._classify_count))
                        
        return True



class OVMSClassifyEncodeOnly:

    def __init__(self,
                 stream=None,
                 **kwargs):
        self._start_time =time.time()
        self._last_report_time = self._start_time
        self._classify_count = 0
        self._latencies = 0
        self._logger = logging.get_logger('remote-classify', is_static=True)
        self._stream = stream
        if not stream:
            self._stream = ""
            

    def process_frame(self, frame):
        with frame.data() as frame_data:
            regions = list(frame.regions())
            for region in regions:
                start = time.time()
                region_rect = region.rect()
                region_data = frame_data[
                    region_rect.y:region_rect.y+region_rect.h,
                    region_rect.x:region_rect.x+region_rect.w
                ]
                _,img = cv2.imencode(".jpeg",region_data)
                self._latencies += (time.time()-start)

        self._classify_count += len(regions)
        if time.time()-self._last_report_time>1 and self._classify_count:
            self._last_report_time=time.time()
            self._logger.info("{} Encode IPS: {}, Average Latency: {}".format(self._stream,
                                                                              self._classify_count/(self._last_report_time-self._start_time),
                                                                              self._latencies / self._classify_count))
            
        return True
    

class OVMSClassifyNoOp:
    def __init__(self,**kwargs):
        pass
    def process_frame(self,frame):
        return True
    
