'''
* Copyright (C) 2023 Intel Corporation.
*
* SPDX-License-Identifier: BSD-3-Clause
'''

import time
import sys
import argparse
import os
import json
from collections import Counter
from dataclasses import dataclass
import traceback

@dataclass
class InferenceCounts:
    detection: int = 0
    classification: int = 0
    text_detection: int = 0
    text_recognition: int = 0
    barcode: int = 0


tracked_objects = {}
frame_count = 0
inferenceCounts = InferenceCounts()

def parse_args():
    parser = argparse.ArgumentParser(prog="Results Parser",
                                     fromfile_prefix_chars='@',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('--mode', default="file", help='Mode: file or mqtt')
    parser.add_argument('--stream-index', default=0, help='Stream index')
    parser.add_argument('--file', default="", help='file name')
    parser.add_argument('--min-detections', default=15, help='Number of detections to define a valid object')
    parser.add_argument('--reclassify-interval', default=1, help='Reclassify interval')
    parser.add_argument('--broker-address', default="localhost", help='MQTT broker address')
    parser.add_argument('--broker-port', default=1883, help='MQTT broker port')
    return parser.parse_args()


def is_inside(inner, outer):
    return inner["x_min"] >= outer["x_min"] and \
           inner["x_max"] <= outer["x_max"] and \
           inner["y_min"] >= outer["y_min"] and \
           inner["y_max"] <= outer["y_max"]

def get_parent_id(detections, detection):
    bbox = detection["bounding_box"]
    for key in detections:
        if is_inside(bbox, detections[key]["bounding_box"]):
            return key
    return 0

def print_object(obj):
    print("  - Object {}: {}".format(obj["id"], obj["label"]))
    print("    - Product: {}".format(obj["product"]))
    print("    - Barcode: {}".format(obj.get("barcode")))
    print("    - Text: {} {}".format(len(obj["text"]),obj["text"]))


def process(results, reclassify_interval):
    product_key = "classification_layer_name:efficientnet-b0/model/head/dense/BiasAdd/Add"
    text_keys = ["inference_layer_name:logits", "inference_layer_name:shadow/LSTMLayers/transpose_time_major",
                 "inference_layer_name:shadow/LSTMLayers/Reshape_1"]
    detections = {}
    objects = {}
    inferenceCounts.detection+=1
    # Needed for additional entries like non-inference results like {"resolution":{"height":2160,"width":3840},"timestamp":201018476}
    if "objects" not in results:
        return
    for result in results["objects"]:
        detection = result["detection"]
        region_id = result["region_id"]
        label = "EMPTY"
        if "label" in detection:
            label = detection["label"]
        if "id" in result:
            tracking_id = result["id"]
            objects[region_id] = {
                "id" : tracking_id,
                "label" : label,
                "text" : [],
                "barcode": None,
                "bounding_box": detection["bounding_box"]
            }
            detections[region_id] = detection
        if product_key in result:
            product = result[product_key]["label"][10:]
            objects[region_id]["product"] = product
        if label.startswith("barcode: "):
            barcode = detection["label"][9:]
            if barcode.endswith("_tracked"):
                barcode = barcode[:-len("_tracked")]
            else:
                inferenceCounts.barcode+=1
            parent_id = get_parent_id(detections, detection)
            if parent_id:
                objects[parent_id]["barcode"] = barcode
        for text_key in text_keys:
            if text_key in result:
                text = result[text_key]["label"]
                inferenceCounts.text_detection+=1
                inferenceCounts.text_recognition+=1
                parent_id = get_parent_id(detections, detection)
                if parent_id:
                    objects[parent_id]["text"].append(text)

    print("- Frame {}".format(frame_count))
    for obj in sorted(objects.values(),key=lambda obj: obj["bounding_box"]["x_min"]):
        print_object(obj)
        update_tracked_object(obj,tracked_objects)


def update_tracked_object(obj, tracked_objects):
    tracked_object = tracked_objects.setdefault(obj["id"],{})
    tracked_keys = ["barcode","text","label","product"]
    tracked_object["id"] = obj["id"]
    for tracked_key in tracked_keys:
        updates = obj[tracked_key]
        if not isinstance(updates,list):
            updates= [updates]
        tracked_object.setdefault(tracked_key,Counter()).update(
            updates)


def process_file(args):
    if args.file:
        filename=args.file
    else:
        filename = "results/r{}.jsonl".format(args.stream_index)
    file = open(filename, "r")
    line = file.readline()
    global frame_count
    while line:
        try:
            results = json.loads(line)
            process(results, args.reclassify_interval)
            frame_count += 1
        except Exception as e:
            print("Error: {}".format(e))
            print(traceback.format_exc())
        line = file.readline()
    file.close()


def on_connect(client, user_data, _unused_flags, return_code):
    if return_code == 0:
        args = user_data
        print("Connected to broker at {}:{}".format(args.broker_address, args.broker_port))
        topic = "gulfstream/results_{}".format(args.stream_index)
        print("Subscribing to topic {}".format(topic))
        client.subscribe(topic)
    else:
        print("Error {} connecting to broker".format(return_code))
        sys.exit(1)

def on_message(_unused_client, user_data, msg):
    results = json.loads(msg.payload)
    process(results)

def process_mqtt(args):
    client = mqtt.Client("Gulfstream", userdata=args)
    client.on_connect = on_connect
    client.on_message = on_message
    client.connect(args.broker_address, args.broker_port)
    client.loop_forever()


def main():
    try:
        args = parse_args()
        if args.mode == "file":
            process_file(args)
        else:
            import paho.mqtt.client as mqtt
            process_mqtt(args)
        text_count = 0
        barcode_count = 0
        print("-------")
        print("Summary")
        print("-------")
        print("Frames {}".format(frame_count))
        inferenceCounts.classification = inferenceCounts.detection
        print(inferenceCounts)
        summary = []
        for obj in tracked_objects.values():
            summary_obj = {}
            id = obj["id"]
            for key in obj:
                if isinstance(obj[key],Counter):
                    print("key is : {}".format(key))
                    if key == "text":
                        obj[key] = {k:v for k, v in obj[key].items() if v > args.min_detections}
                    summary_obj[key] = list(obj[key].items())
                    obj[key] = list(obj[key].items())
                    if key == "barcode":
                        if None in obj[key][0]:
                            print("barcode is None, skip")
                        else:
                            print("barcode found: {}".format(obj[key][0]))
                            barcode_count += 1
                else:
                    summary_obj[key] = obj[key]
                    print("obj[key]: {}".format(obj[key]))
            detections = obj["label"][0][1]
            if detections >= args.min_detections:
                print_object(obj)
                text_count += len(obj["text"])
                summary.append(summary_obj)
        print(json.dumps(summary))
        print("Total Objects: {} ".format(len(obj)))
        print("Total Text count: {}".format(text_count))
        print("Total Barcode count: {}".format(barcode_count))
    except:
        print(traceback.format_exc())

if __name__ == "__main__":
    main()
