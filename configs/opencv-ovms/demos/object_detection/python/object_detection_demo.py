#!/usr/bin/env python3
"""
 Copyright (C) 2018-2023 Intel Corporation

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
from argparse import ArgumentParser, SUPPRESS
from pathlib import Path
from time import perf_counter
import json
import time

import cv2
import os

sys.path.append(str(Path(__file__).resolve().parents[2] / 'common/python'))
sys.path.append(str(Path(__file__).resolve().parents[2] / 'common/python/openvino/model_zoo'))

from model_api.models import DetectionModel, DetectionWithLandmarks, RESIZE_TYPES, OutputTransform
from model_api.performance_metrics import PerformanceMetrics
from model_api.pipelines import get_user_config, AsyncPipeline
from model_api.adapters import create_core, OpenvinoAdapter, OVMSAdapter

import monitors
from images_capture import open_images_capture
from helpers import resolution, log_latency_per_stage
from visualizers import ColorPalette
import paho.mqtt.client as mqtt

log.basicConfig(format='[ %(levelname)s ] %(message)s', level=log.DEBUG, stream=sys.stdout)


def build_argparser():
    parser = ArgumentParser(add_help=False)
    args = parser.add_argument_group('Options')
    args.add_argument('-h', '--help', action='help', default=SUPPRESS, help='Show this help message and exit.')
    args.add_argument('-mqtt', '--mqtt',
                      help='Optional. Set mqtt broker host to publish results. Example: 127.0.0.1:1883',type=str)
    args.add_argument('-m', '--model', required=True,
                      help='Required. Path to an .xml file with a trained model '
                           'or address of model inference service if using ovms adapter.')
    available_model_wrappers = [name.lower() for name in DetectionModel.available_wrappers()]
    args.add_argument('-at', '--architecture_type', help='Required. Specify model\' architecture type.',
                      type=str, required=True, choices=available_model_wrappers)
    args.add_argument('--adapter', help='Optional. Specify the model adapter. Default is openvino.',
                      default='openvino', type=str, choices=('openvino', 'ovms'))
    args.add_argument('-i', '--input', required=True,
                      help='Required. An input to process. The input must be a single image, '
                           'a folder of images, video file or camera id.')
    args.add_argument('-d', '--device', default='CPU', type=str,
                      help='Optional. Specify the target device to infer on; CPU or GPU is '
                           'acceptable. The demo will look for a suitable plugin for device specified. '
                           'Default value is CPU.')

    common_model_args = parser.add_argument_group('Common model options')
    common_model_args.add_argument('--labels', help='Optional. Labels mapping file.', default=None, type=str)
    common_model_args.add_argument('-t', '--prob_threshold', default=0.5, type=float,
                                   help='Optional. Probability threshold for detections filtering.')
    common_model_args.add_argument('--resize_type', default=None, choices=RESIZE_TYPES.keys(),
                                   help='Optional. A resize type for model preprocess. By default used model predefined type.')
    common_model_args.add_argument('--input_size', default=(600, 600), type=int, nargs=2,
                                   help='Optional. The first image size used for CTPN model reshaping. '
                                        'Default: 600 600. Note that submitted images should have the same resolution, '
                                        'otherwise predictions might be incorrect.')
    common_model_args.add_argument('--anchors', default=None, type=float, nargs='+',
                                   help='Optional. A space separated list of anchors. '
                                        'By default used default anchors for model. Only for YOLOV4 architecture type.')
    common_model_args.add_argument('--masks', default=None, type=int, nargs='+',
                                   help='Optional. A space separated list of mask for anchors. '
                                        'By default used default masks for model. Only for YOLOV4 architecture type.')
    common_model_args.add_argument('--layout', type=str, default=None,
                                   help='Optional. Model inputs layouts. '
                                        'Ex. NCHW or input0:NCHW,input1:NC in case of more than one input.')
    common_model_args.add_argument('--num_classes', default=None, type=int,
                                   help='Optional. Number of detected classes. Only for NanoDet, NanoDetPlus '
                                        'architecture types.')

    infer_args = parser.add_argument_group('Inference options')
    infer_args.add_argument('-nireq', '--num_infer_requests', help='Optional. Number of infer requests',
                            default=0, type=int)
    infer_args.add_argument('-nstreams', '--num_streams',
                            help='Optional. Number of streams to use for inference on the CPU or/and GPU in throughput '
                                 'mode (for HETERO and MULTI device cases use format '
                                 '<device1>:<nstreams1>,<device2>:<nstreams2> or just <nstreams>).',
                            default='', type=str)
    infer_args.add_argument('-nthreads', '--num_threads', default=None, type=int,
                            help='Optional. Number of threads to use for inference on CPU (including HETERO cases).')

    io_args = parser.add_argument_group('Input/output options')
    io_args.add_argument('--loop', default=False, action='store_true',
                         help='Optional. Enable reading the input in a loop.')
    io_args.add_argument('-o', '--output', required=False,
                         help='Optional. Name of the output file(s) to save.')
    io_args.add_argument('-limit', '--output_limit', required=False, default=1000, type=int,
                         help='Optional. Number of frames to store in output. '
                              'If 0 is set, all frames are stored.')
    io_args.add_argument('--no_show', help="Optional. Don't show output.", action='store_true')
    io_args.add_argument('--output_resolution', default=None, type=resolution,
                         help='Optional. Specify the maximum output window resolution '
                              'in (width x height) format. Example: 1280x720. '
                              'Input frame size used by default.')
    io_args.add_argument('-u', '--utilization_monitors', default='', type=str,
                         help='Optional. List of monitors to show initially.')

    input_transform_args = parser.add_argument_group('Input transform options')
    input_transform_args.add_argument('--reverse_input_channels', default=False, action='store_true',
                                      help='Optional. Switch the input channels order from '
                                           'BGR to RGB.')
    input_transform_args.add_argument('--mean_values', default=None, type=float, nargs=3,
                                      help='Optional. Normalize input by subtracting the mean '
                                           'values per channel. Example: 255.0 255.0 255.0')
    input_transform_args.add_argument('--scale_values', default=None, type=float, nargs=3,
                                      help='Optional. Divide input by scale values per channel. '
                                           'Division is applied after mean values subtraction. '
                                           'Example: 255.0 255.0 255.0')

    debug_args = parser.add_argument_group('Debug options')
    debug_args.add_argument('-r', '--raw_output_message', help='Optional. Output inference results raw values showing.',
                            default=False, action='store_true')
    return parser


def draw_detections(frame, detections, palette, labels, output_transform):
    frame = output_transform.resize(frame)
    for detection in detections:
        class_id = int(detection.id)
        color = palette[class_id]
        det_label = labels[class_id] if labels and len(labels) >= class_id else '#{}'.format(class_id)
        xmin, ymin, xmax, ymax = detection.get_coords()
        xmin, ymin, xmax, ymax = output_transform.scale([xmin, ymin, xmax, ymax])
        cv2.rectangle(frame, (xmin, ymin), (xmax, ymax), color, 2)
        cv2.putText(frame, '{} {:.1%}'.format(det_label, detection.score),
                    (xmin, ymin - 7), cv2.FONT_HERSHEY_COMPLEX, 0.6, color, 1)
        if isinstance(detection, DetectionWithLandmarks):
            for landmark in detection.landmarks:
                landmark = output_transform.scale(landmark)
                cv2.circle(frame, (int(landmark[0]), int(landmark[1])), 2, (0, 255, 255), 2)
    return frame


def print_raw_results(detections, labels, frame_id):    
    data = []
    for detection in detections:
        xmin, ymin, xmax, ymax = detection.get_coords()
        class_id = int(detection.id)
        det_label = labels[class_id] if labels and len(labels) >= class_id else '#{}'.format(class_id)
        json_object = {
            "label": det_label,
            "score": float(detection.score),
            "xmin": xmin,
            "ymin": ymin,
            "xmax": xmax,
            "ymax": ymax
        }
        data.append(json_object)
    json_array = json.dumps(data)
    return json_array      

def main():
    args = build_argparser().parse_args()
    if args.architecture_type != 'yolov4' and args.anchors:
        log.warning('The "--anchors" option works only for "-at==yolov4". Option will be omitted')
    if args.architecture_type != 'yolov4' and args.masks:
        log.warning('The "--masks" option works only for "-at==yolov4". Option will be omitted')
    if args.architecture_type not in ['nanodet', 'nanodet-plus'] and args.num_classes:
        log.warning('The "--num_classes" option works only for "-at==nanodet" and "-at==nanodet-plus". Option will be omitted')
        
    containerName = os.environ.get("CONTAINER_NAME", "object_detection") 
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

    cap = open_images_capture(args.input, args.loop)
    
    # Overwritting --no_show 
    render = os.environ.get("RENDER_MODE", "0")        
    if render == "1":
        args.no_show = False
    elif render == "0":
        args.no_show = True

    if args.adapter == 'openvino':
        plugin_config = get_user_config(args.device, args.num_streams, args.num_threads)
        model_adapter = OpenvinoAdapter(create_core(), args.model, device=args.device, plugin_config=plugin_config,
                                        max_num_requests=args.num_infer_requests, model_parameters = {'input_layouts': args.layout})
    elif args.adapter == 'ovms':
        model_adapter = OVMSAdapter(args.model)

    if (args.prob_threshold < 0.0) or (args.prob_threshold > 1.0):
        print("Detection threshold: {}, is confidence threshold value in floating point that needs to be between 0.0 to 1.0.".format(args.prob_threshold))
        return 1

    configuration = {
        'resize_type': args.resize_type,
        'mean_values': args.mean_values,
        'scale_values': args.scale_values,
        'reverse_input_channels': args.reverse_input_channels,
        'path_to_labels': args.labels,
        'confidence_threshold': args.prob_threshold,
        'input_size': args.input_size, # The CTPN specific
        'num_classes': args.num_classes, # The NanoDet and NanoDetPlus specific
    }
    model = DetectionModel.create_model(args.architecture_type, model_adapter, configuration)
    model.log_layers_info()

    detector_pipeline = AsyncPipeline(model)

    next_frame_id = 0
    next_frame_id_to_show = 0

    palette = ColorPalette(len(model.labels) if model.labels else 100)
    metrics = PerformanceMetrics()
    render_metrics = PerformanceMetrics()
    presenter = None
    output_transform = None
    video_writer = cv2.VideoWriter()

    while True:
        if detector_pipeline.callback_exceptions:
            raise detector_pipeline.callback_exceptions[0]
        # Process all completed requests
        results = detector_pipeline.get_result(next_frame_id_to_show)
        if results:
            objects, frame_meta = results
            frame = frame_meta['frame']
            start_time = frame_meta['start_time']
            presenter.drawGraphs(frame)
            rendering_start_time = perf_counter()
            frame = draw_detections(frame, objects, palette, model.labels, output_transform)
            render_metrics.update(rendering_start_time)
            metrics.update(start_time, frame)

            if video_writer.isOpened() and (args.output_limit <= 0 or next_frame_id_to_show <= args.output_limit-1):
                video_writer.write(frame)
            next_frame_id_to_show += 1
            
            total_latency, total_fps = metrics.get_total() 
            print("Processing time: {:.2f} ms; fps: {:.2f}".format(total_latency * 1e3,total_fps))
            
            # Publish results to mqtt   
            if args.mqtt:         
                json_objects = print_raw_results(objects, model.labels, next_frame_id_to_show)
                client.publish(containerName,json_objects)                      
                
            if not args.no_show:
                cv2.imshow('Detection Results', frame)
                key = cv2.waitKey(1)

                ESC_KEY = 27
                # Quit.
                if key in {ord('q'), ord('Q'), ESC_KEY}:
                    break
                presenter.handleKey(key)
            continue

        if detector_pipeline.is_ready():
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
            detector_pipeline.submit_data(frame, next_frame_id, {'frame': frame, 'start_time': start_time})
            next_frame_id += 1
        else:
            # Wait for empty request
            detector_pipeline.await_any()

    detector_pipeline.await_all()
    if detector_pipeline.callback_exceptions:
        raise detector_pipeline.callback_exceptions[0]
    # Process completed requests
    for next_frame_id_to_show in range(next_frame_id_to_show, next_frame_id):
        results = detector_pipeline.get_result(next_frame_id_to_show)
        objects, frame_meta = results
        frame = frame_meta['frame']
        start_time = frame_meta['start_time']

        if len(objects) and args.raw_output_message:
            print_raw_results(objects, model.labels, next_frame_id_to_show)     

        presenter.drawGraphs(frame)
        rendering_start_time = perf_counter()
        frame = draw_detections(frame, objects, palette, model.labels, output_transform)
        render_metrics.update(rendering_start_time)
        metrics.update(start_time, frame)

        if video_writer.isOpened() and (args.output_limit <= 0 or next_frame_id_to_show <= args.output_limit-1):
            video_writer.write(frame)

        if not args.no_show:
            cv2.imshow('Detection Results', frame)
            key = cv2.waitKey(1)

            ESC_KEY = 27
            # Quit.
            if key in {ord('q'), ord('Q'), ESC_KEY}:
                break
            presenter.handleKey(key)

    metrics.log_total()
    log_latency_per_stage(cap.reader_metrics.get_latency(),
                          detector_pipeline.preprocess_metrics.get_latency(),
                          detector_pipeline.inference_metrics.get_latency(),
                          detector_pipeline.postprocess_metrics.get_latency(),
                          render_metrics.get_latency())
    for rep in presenter.reportMeans():
        log.info(rep)
    client.disconnect()

if __name__ == '__main__':
    sys.exit(main() or 0)
