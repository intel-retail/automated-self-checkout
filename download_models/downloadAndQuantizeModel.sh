#!/bin/bash
# ==============================================================================
# Copyright (C) 2021-2025 Intel Corporation
#
# SPDX-License-Identifier: MIT
# ==============================================================================
# Check Python version compatibility (OpenVINO/NNCF require Python 3.10 or 3.11)

# Set proxy variables for all tools and environments
if [ -n "$HTTP_PROXY" ]; then
    export http_proxy="$HTTP_PROXY"
fi
if [ -n "$HTTPS_PROXY" ]; then
    export https_proxy="$HTTPS_PROXY"
fi

declare -A SUPPORTED_QUANTIZATION_DATASETS
SUPPORTED_QUANTIZATION_DATASETS=(
  ["coco"]="https://raw.githubusercontent.com/ultralytics/ultralytics/v8.1.0/ultralytics/cfg/datasets/coco.yaml"
  ["coco128"]="https://raw.githubusercontent.com/ultralytics/ultralytics/v8.1.0/ultralytics/cfg/datasets/coco128.yaml"
)

# Use host path for models if provided, otherwise default
MODELS_PATH="${MODELS_DIR:-/workspace/models}"
MODEL_NAME="yolo11n"
MODEL_TYPE="yolo_v11"
QUANTIZE=INT8


export_yolo_model() {
  echo "Calling export_yolo_model function: ${MODEL_DIR}"  
  MODEL_DIR="$MODELS_PATH/object_detection/$MODEL_NAME"
  DST_FILE1="$MODEL_DIR/FP16/$MODEL_NAME.xml"
  DST_FILE2="$MODEL_DIR/FP32/$MODEL_NAME.xml"

  if [[ ! -f "$DST_FILE1" || ! -f "$DST_FILE2" ]]; then
    echo "Downloading and converting: ${MODEL_DIR}"
    mkdir -p "$MODEL_DIR"
    cd "$MODEL_DIR"

    python3 - <<EOF "$MODEL_NAME" "$MODEL_TYPE"
from ultralytics import YOLO
import openvino, sys, shutil, os

model_name = sys.argv[1]
model_type = sys.argv[2]
weights = model_name + '.pt'

model = YOLO(weights)
model.info()
converted_path = model.export(format='openvino')
converted_model = converted_path + '/' + model_name + '.xml'
core = openvino.Core()
ov_model = core.read_model(model=converted_model)

if model_type in ["YOLOv8-SEG", "yolo_v11_seg"]:
    ov_model.output(0).set_names({"boxes"})
    ov_model.output(1).set_names({"masks"})

ov_model.set_rt_info(model_type, ['model_info', 'model_type'])

openvino.save_model(ov_model, './FP32/' + model_name + '.xml', compress_to_fp16=False)
openvino.save_model(ov_model, './FP16/' + model_name + '.xml', compress_to_fp16=True)
shutil.rmtree(converted_path)
os.remove(f"{model_name}.pt")
EOF

    cd ../..
  else
    echo "Model already exists: $MODEL_DIR. Skipping download."
  fi

  if [[ $QUANTIZE != "" ]]; then
    quantize_model "$MODEL_NAME"
  fi
}

quantize_model() {
  echo "###########################quantize_model###########################"; 
  local MODEL_NAME=$1
  MODEL_DIR="$MODELS_PATH/object_detection/$MODEL_NAME"
  DST_FILE="$MODEL_DIR/INT8/$MODEL_NAME.xml"
  echo "###########################DST_FILE###########################"$DST_FILE; 
  # Use coco128 as default quantization dataset if not set
  QUANT_DATASET_KEY="coco128"
  DATASET_URL=${SUPPORTED_QUANTIZATION_DATASETS[$QUANT_DATASET_KEY]}
  if [ -z "$DATASET_URL" ]; then
    echo "[ERROR] No quantization dataset URL found for key $QUANT_DATASET_KEY"; exit 1;
  fi

  if [[ ! -f "$DST_FILE" ]]; then
    YOLO_CONFIG_DIR=$QUANTIZE_CONFIG_DIR
    export YOLO_CONFIG_DIR

    mkdir -p "$MODELS_PATH/datasets"
    local DATASET_MANIFEST="$MODELS_PATH/datasets/$QUANT_DATASET_KEY.yaml"

    if [ ! -f "$DATASET_MANIFEST" ]; then
        wget --timeout=30 --tries=2 "$DATASET_URL" -O "$DATASET_MANIFEST" || { echo "[ERROR] Failed to download quantization dataset"; exit 1; }
    else
        echo "[INFO] Using local quantization dataset: $DATASET_MANIFEST"
    fi
    echo "Quantizing: ${MODEL_DIR}"
    mkdir -p "$MODEL_DIR"

    cd "$MODELS_PATH"
    python3 - <<EOF "$MODEL_NAME" "$DATASET_MANIFEST"
import openvino as ov
import nncf
import torch
import sys
from rich.progress import track
from ultralytics.cfg import get_cfg
from ultralytics.models.yolo.detect import DetectionValidator
from ultralytics.data.converter import coco80_to_coco91_class
from ultralytics.data.utils import check_det_dataset
from ultralytics.utils import DATASETS_DIR
from ultralytics.utils import DEFAULT_CFG
from ultralytics.utils.metrics import ConfusionMatrix
import os

def validate(
    model: ov.Model, data_loader: torch.utils.data.DataLoader, validator: DetectionValidator, num_samples: int = None
) -> tuple[dict, int]:
    validator.seen = 0
    validator.jdict = []
    validator.stats = dict(tp=[], conf=[], pred_cls=[], target_cls=[], target_img=[])
    validator.end2end = False
    validator.confusion_matrix = ConfusionMatrix(validator.data["names"])
    compiled_model = ov.compile_model(model, device_name="CPU")
    output_layer = compiled_model.output(0)
    for batch_i, batch in enumerate(track(data_loader, description="Validating")):
        if num_samples is not None and batch_i == num_samples:
            break
        batch = validator.preprocess(batch)
        preds = torch.from_numpy(compiled_model(batch["img"])[output_layer])
        preds = validator.postprocess(preds)
        validator.update_metrics(preds, batch)
    stats = validator.get_stats()
    return stats, validator.seen

def print_statistics(stats: dict[str, float], total_images: int) -> None:
    mp, mr, map50, mean_ap = (
        stats["metrics/precision(B)"],
        stats["metrics/recall(B)"],
        stats["metrics/mAP50(B)"],
        stats["metrics/mAP50-95(B)"],
    )
    s = ("%20s" + "%12s" * 5) % ("Class", "Images", "Precision", "Recall", "mAP@.5", "mAP@.5:.95")
    print(s)
    pf = "%20s" + "%12i" + "%12.3g" * 4  # print format
    print(pf % ("all", total_images, mp, mr, map50, mean_ap))

model_name = sys.argv[1]
dataset_file = sys.argv[2]


validator = DetectionValidator()
validator.data = check_det_dataset(dataset_file)
validator.stride = 32
validator.is_coco = True
validator.class_map = coco80_to_coco91_class

data_loader = validator.get_dataloader(validator.data["path"], 1)

def transform_fn(data_item: dict):
    input_tensor = validator.preprocess(data_item)["img"].numpy()
    return input_tensor
    # images, _ = data_item
    # return images.numpy()

calibration_dataset = nncf.Dataset(data_loader, transform_fn)

model = ov.Core().read_model("./object_detection/" + model_name + "/FP32/" + model_name + ".xml")
quantized_model = nncf.quantize(model, calibration_dataset, subset_size = len(data_loader))

# Validate FP32 model
fp_stats, total_images = validate(model, data_loader, validator)
print("Floating-point model validation results:")
print_statistics(fp_stats, total_images)

# Validate quantized model
q_stats, total_images = validate(quantized_model, data_loader, validator)
print("Quantized model validation results:")
print_statistics(q_stats, total_images)

quantized_model.set_rt_info(ov.get_version(), "Runtime_version")
# Save INT8 model to object_detection/<MODEL_NAME>/INT8
output_int8_dir = f"./object_detection/{model_name}/INT8"
os.makedirs(output_int8_dir, exist_ok=True)
ov.save_model(quantized_model, f"{output_int8_dir}/{model_name}.xml", compress_to_fp16=False)
# Clean up datasets and runs directories if they exist
import shutil
for d in ["datasets", "runs"]:
    if os.path.exists(d):
        shutil.rmtree(d)
EOF

    cd -
  else
    echo "Model already quantized: $MODEL_DIR. Skipping quantization."
  fi
}

# Call the main function to start the process
export_yolo_model