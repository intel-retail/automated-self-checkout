# download_convert_model.py

import argparse
import os
import shutil
from ultralytics import YOLO
import openvino
import numpy as np
from openvino.runtime import Core, serialize
from nncf import Dataset, quantize


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
    if os.path.exists(weights):
        os.remove(weights)

    return fp32_dir, fp16_dir


def quantize_model(model_name, output_dir):
    print(f" in quantize_model Model Name: {model_name}")
    fp16_path = os.path.join(output_dir, "FP16", f"{model_name}.xml")
    int8_dir = os.path.join(output_dir, "INT8")
    os.makedirs(int8_dir, exist_ok=True)
    core = Core()
    model = core.read_model(fp16_path)
    input_key = model.inputs[0].get_any_name()
    print(f"✅ Model input key: {input_key}, shape: {model.inputs[0].shape}")

    def data_gen():
        for _ in range(10):
            dummy = np.random.rand(1, 3, 640, 640).astype(np.float32)
            yield {input_key: dummy}

    dataset = Dataset(data_gen())
    quantized_model = quantize(
        model=model,
        calibration_dataset=dataset,
        subset_size=10
    )

    int8_xml = os.path.join(int8_dir, f"{model_name}-int8.xml")
    int8_bin = os.path.join(int8_dir, f"{model_name}-int8.bin")
    serialize(model=quantized_model, xml_path=int8_xml, bin_path=int8_bin)
    print(f"[DONE] INT8 model saved to: {int8_dir}")
    return fp16_path, int8_xml

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download and convert YOLO model to OpenVINO IR format.")
    parser.add_argument("model_name", nargs="?", default="yolo11n", help="Model name (default: yolo11n)")
    parser.add_argument("model_type", nargs="?", default="yolo_v11", help="Model type (default: yolo_v11)")
    parser.add_argument("--output_dir", default=".", help="Output directory for converted models")

    args = parser.parse_args()
    convert_model(args.model_name, args.model_type, args.output_dir)
    quantize_model(args.model_name, args.output_dir)