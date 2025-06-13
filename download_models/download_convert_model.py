# download_convert_model.py

import argparse
import os
import shutil
from ultralytics import YOLO
import openvino

def convert_model(model_name, model_type, output_dir):
    print(f"Model Name: {model_name}")
    print(f"Model Type: {model_type}")
    print(f"Output Directory: {output_dir}")

    weights = model_name + '.pt'

    if not os.path.exists(weights):
        print(f"{weights} not found. Downloading...")
        YOLO(model_name)  # auto-download if available

    model = YOLO(weights)
    model.info()

    converted_path = model.export(format='openvino')
    converted_model = os.path.join(converted_path, model_name + '.xml')

    core = openvino.Core()
    ov_model = core.read_model(model=converted_model)

    if model_type in ["YOLOv8-SEG", "yolo_v11_seg"]:
        ov_model.output(0).set_names({"boxes"})
        ov_model.output(1).set_names({"masks"})

    ov_model.set_rt_info(model_type, ['model_info', 'model_type'])

    # Save to output_dir (default: ./FP32 and ./FP16 inside output_dir)
    fp32_dir = os.path.join(output_dir, 'FP32')
    fp16_dir = os.path.join(output_dir, 'FP16')
    os.makedirs(fp32_dir, exist_ok=True)
    os.makedirs(fp16_dir, exist_ok=True)

    openvino.save_model(ov_model, os.path.join(fp32_dir, model_name + '.xml'), compress_to_fp16=False)
    openvino.save_model(ov_model, os.path.join(fp16_dir, model_name + '.xml'), compress_to_fp16=True)

    shutil.rmtree(converted_path)
    os.remove(weights)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download and convert YOLO model to OpenVINO IR format.")
    parser.add_argument("model_name", nargs="?", default="yolo11s", help="Model name (default: yolo11s)")
    parser.add_argument("model_type", nargs="?", default="yolo_v11", help="Model type (default: yolo_v11)")
    parser.add_argument("--output_dir", default=".", help="Output directory for converted models")

    args = parser.parse_args()
    convert_model(args.model_name, args.model_type, args.output_dir)

