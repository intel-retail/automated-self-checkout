#!/usr/bin/env python3
"""
 Copyright (c) 2019-2023 Intel Corporation

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
"""

import logging as log
import sys
from time import perf_counter
from argparse import ArgumentParser
from pathlib import Path
import time

import cv2

from instance_segmentation_demo.tracker import StaticIOUTracker

import paho.mqtt.client as mqtt
import json

sys.path.append(str(Path(__file__).resolve().parents[2] / 'common/python'))
sys.path.append(str(Path(__file__).resolve().parents[2] / 'common/python/openvino/model_zoo'))

from model_api.models import MaskRCNNModel, YolactModel, OutputTransform
from model_api.adapters import create_core, OpenvinoAdapter, OVMSAdapter
from model_api.pipelines import get_user_config, AsyncPipeline
from model_api.performance_metrics import PerformanceMetrics

import os
import monitors
import subprocess
from images_capture import open_images_capture
from helpers import resolution, log_latency_per_stage
from visualizers import InstanceSegmentationVisualizer


log.basicConfig(format='[ %(levelname)s ] %(message)s', level=log.DEBUG, stream=sys.stdout)

def build_argparser():
    parser = ArgumentParser()
    args = parser.add_argument_group('Options')
    args.add_argument('-m', '--model', required=True,
                      help='Required. Path to an .xml file with a trained model '
                           'or address of model inference service if using ovms adapter.')
    args.add_argument('-mqtt', '--mqtt',
                      help='Optional. Set mqtt broker host to publish results. Example: 127.0.0.1:1883',type=str)
    args.add_argument('--adapter', default='openvino', choices=('openvino', 'ovms'),
                      help='Optional. Specify the model adapter. Default is openvino.')
    args.add_argument('-i', '--input', required=True,
                      help='Required. An input to process. The input must be a single image, '
                           'a folder of images, video file or camera id.')
    args.add_argument('-d', '--device', default='CPU',
                      help='Optional. Specify the target device to infer on; CPU or GPU is '
                           'acceptable. The demo will look for a suitable plugin for device specified. '
                           'Default value is CPU.')

    common_model_args = parser.add_argument_group('Common model options')
    common_model_args.add_argument('--labels', required=True,
                                   help='Required. Path to a text file with class labels.')
    common_model_args.add_argument('-t', '--prob_threshold', default=0.5, type=float,
                                   help='Optional. Probability threshold for detections filtering.')
    common_model_args.add_argument('--no_track', action='store_true',
                                   help='Optional. Disable object tracking for video/camera input.')
    common_model_args.add_argument('--show_scores', action='store_true',
                                   help='Optional. Show detection scores.')
    common_model_args.add_argument('--show_boxes', action='store_true',
                                   help='Optional. Show bounding boxes.')
    common_model_args.add_argument('--layout', type=str, default=None,
                                   help='Optional. Model inputs layouts. '
                                        'Format "[<layout>]" or "<input1>[<layout1>],<input2>[<layout2>]" in case of more than one input. '
                                        'To define layout you should use only capital letters')

    infer_args = parser.add_argument_group('Inference options')
    infer_args.add_argument('-nireq', '--num_infer_requests', default=0, type=int,
                            help='Optional. Number of infer requests')
    infer_args.add_argument('-nstreams', '--num_streams', default='',
                            help='Optional. Number of streams to use for inference on the CPU or/and GPU in throughput '
                                 'mode (for HETERO and MULTI device cases use format '
                                 '<device1>:<nstreams1>,<device2>:<nstreams2> or just <nstreams>).')
    infer_args.add_argument('-nthreads', '--num_threads', default=None, type=int,
                            help='Optional. Number of threads to use for inference on CPU (including HETERO cases).')

    io_args = parser.add_argument_group('Input/output options')
    io_args.add_argument('--loop', action='store_true',
                         help='Optional. Enable reading the input in a loop.')
    io_args.add_argument('-o', '--output',
                         help='Optional. Name of the output file(s) to save.')
    io_args.add_argument('-limit', '--output_limit', default=1000, type=int,
                         help='Optional. Number of frames to store in output. '
                              'If 0 is set, all frames are stored.')
    io_args.add_argument('--no_show', action='store_true',
                         help="Optional. Don't show output.")
    io_args.add_argument('--output_resolution', default=None, type=resolution,
                         help='Optional. Specify the maximum output window resolution '
                              'in (width x height) format. Example: 1280x720. '
                              'Input frame size used by default.')
    io_args.add_argument('-u', '--utilization_monitors',
                         help='Optional. List of monitors to show initially.')

    debug_args = parser.add_argument_group('Debug options')
    debug_args.add_argument('-r', '--raw_output_message', action='store_true',
                             help='Optional. Output inference results raw values showing.')
    return parser


def get_model(model_adapter, configuration):
    inputs = model_adapter.get_input_layers()
    outputs = model_adapter.get_output_layers()
    if len(inputs) == 1 and len(outputs) == 4 and 'proto' in outputs.keys():
        return YolactModel(model_adapter, configuration)
    return MaskRCNNModel(model_adapter, configuration)


def print_raw_results(boxes, classes, labels, scores, frame_id):
    data = []
    for box, cls, score in zip(boxes, classes, scores):
        det_label = labels[cls] if labels and len(labels) >= cls else '#{}'.format(cls)
        json_object = {
            "label": det_label,
            "score": float(score),
            "xmin": float(box[0]),
            "ymin": float(box[1]),
            "xmax": float(box[2]),
            "ymax": float(box[3])
        }
        data.append(json_object)
    json_array = json.dumps(data)
    return json_array  

def main():
      
    args = build_argparser().parse_args()

    cap = open_images_capture(args.input, args.loop)
    
    containerName = os.environ.get("CONTAINER_NAME", "segmentation") 
    client = None
    # Connect to MQTT
    if args.mqtt:
        try:
            mqttInfo = args.mqtt.split(':',1)             
            client = mqtt.Client(containerName)
            if len(mqttInfo) == 2:
                client.connect(mqttInfo[0],int(mqttInfo[1]),60)    
                client.loop_start()
                print(f"connected to mqtt: {args.mqtt}")
        except Exception as e:
            print("Connection failed to mqtt: {}".format(e))

    # Overwritting --no_show 
    render = os.environ.get("RENDER_MODE", "0")        
    if render == "1":
        args.no_show = False
    elif render == "0":
        args.no_show = True

    if args.adapter == 'openvino':
        plugin_config = get_user_config(args.device, args.num_streams, args.num_threads)
        model_adapter = OpenvinoAdapter(create_core(), args.model, device=args.device, plugin_config=plugin_config,
                                        max_num_requests=args.num_infer_requests,
                                        model_parameters={'input_layouts': args.layout})
    elif args.adapter == 'ovms':
        model_adapter = OVMSAdapter(args.model)

    configuration = {
        'confidence_threshold': args.prob_threshold,
        'path_to_labels': args.labels,
    }
    model = get_model(model_adapter, configuration)
    model.log_layers_info()

    pipeline = AsyncPipeline(model)

    next_frame_id = 0
    next_frame_id_to_show = 0

    tracker = None
    if not args.no_track and cap.get_type() in {'VIDEO', 'CAMERA'}:
        tracker = StaticIOUTracker()
    visualizer = InstanceSegmentationVisualizer(model.labels, args.show_boxes, args.show_scores)

    metrics = PerformanceMetrics()
    render_metrics = PerformanceMetrics()
    presenter = None
    output_transform = None
    video_writer = cv2.VideoWriter()

    while True:
        if pipeline.is_ready():
            # Get new image/frame
            start_time = perf_counter()
            status,frame = cap.read() 
            # If errors during decoding, then retry grab new image/frame           
            if not(status):                
                st = time.time()
                for retry in range(3):                    
                    try:
                        cap = open_images_capture(args.input, args.loop)
                        print("time lost due to reinitialization: ", time.time() - st)
                        break  # If successful, exit the loop
                    except Exception as e:
                        print(f"Error on attempt reinitialization {retry + 1}: {e}")
                        if retry < 2:
                            print("Retrying...")
                            time.sleep(1)
                        else:
                            print("Max retries reached. Exiting.")
                            raise RuntimeError("Can't reinitialize image capture") 
                continue                       
            if frame is None:
                if next_frame_id == 0:
                    raise ValueError("Can't read an image from the input")
                break
            if next_frame_id == 0:
                output_transform = OutputTransform(frame.shape[:2], args.output_resolution)
                if args.output_resolution:
                    output_resolution = output_transform.new_resolution
                else:
                    output_resolution = (frame.shape[1], frame.shape[0])
                presenter = monitors.Presenter(args.utilization_monitors, 55,
                                               (round(output_resolution[0] / 4), round(output_resolution[1] / 8)))
                if args.output and not video_writer.open(args.output, cv2.VideoWriter_fourcc(*'MJPG'),
                                                         cap.fps(), output_resolution):
                    raise RuntimeError("Can't open video writer")
            # Submit for inference
            pipeline.submit_data(frame, next_frame_id, {'frame': frame, 'start_time': start_time})
            next_frame_id += 1
        else:
            # Wait for empty request
            pipeline.await_any()

        if pipeline.callback_exceptions:
            raise pipeline.callback_exceptions[0]
        # Process all completed requests
        results = pipeline.get_result(next_frame_id_to_show)
        if results:
            (scores, classes, boxes, masks), frame_meta = results
            frame = frame_meta['frame']
            start_time = frame_meta['start_time']

            if args.mqtt:
                json_objects = print_raw_results(boxes, classes, model.labels, scores, next_frame_id_to_show)                
                client.publish(containerName,json_objects)            

            rendering_start_time = perf_counter()
            masks_tracks_ids = tracker(masks, classes) if tracker else None
            frame = visualizer(frame, boxes, classes, scores, output_transform, masks, masks_tracks_ids)
            render_metrics.update(rendering_start_time)

            presenter.drawGraphs(frame)
            metrics.update(start_time, frame)

            total_latency, total_fps = metrics.get_total()            
            print("Processing time: {:.2f} ms; fps: {:.2f}".format(total_latency * 1e3,total_fps))           
            
            if video_writer.isOpened() and (args.output_limit <= 0 or next_frame_id_to_show <= args.output_limit - 1):
                video_writer.write(frame)
            next_frame_id_to_show += 1

            if not args.no_show:                             
                cv2.imshow('Instance Segmentation results', frame)
                key = cv2.waitKey(1)
                if key == 27 or key == 'q' or key == 'Q':
                    break
                presenter.handleKey(key)

    pipeline.await_all()
    if pipeline.callback_exceptions:
        raise pipeline.callback_exceptions[0]
    # Process completed requests
    for next_frame_id_to_show in range(next_frame_id_to_show, next_frame_id):
        results = pipeline.get_result(next_frame_id_to_show)
        (scores, classes, boxes, masks), frame_meta = results
        frame = frame_meta['frame']
        start_time = frame_meta['start_time']

        if args.raw_output_message:
            print_raw_results(boxes, classes, scores, next_frame_id_to_show)

        rendering_start_time = perf_counter()
        masks_tracks_ids = tracker(masks, classes) if tracker else None
        frame = visualizer(frame, boxes, classes, scores, masks, masks_tracks_ids)
        render_metrics.update(rendering_start_time)

        presenter.drawGraphs(frame)
        metrics.update(start_time, frame)

        if video_writer.isOpened() and (args.output_limit <= 0 or next_frame_id_to_show <= args.output_limit - 1):
            video_writer.write(frame)

        if not args.no_show:
            cv2.imshow('Instance Segmentation results', frame)
            cv2.waitKey(1)
            out.write(frame)
    
    metrics.log_total()
    log_latency_per_stage(cap.reader_metrics.get_latency(),
                          pipeline.preprocess_metrics.get_latency(),
                          pipeline.inference_metrics.get_latency(),
                          pipeline.postprocess_metrics.get_latency(),
                          render_metrics.get_latency())
    for rep in presenter.reportMeans():
        log.info(rep)       
        print(rep)
    client.disconnect()

if __name__ == '__main__':
    sys.exit(main() or 0)