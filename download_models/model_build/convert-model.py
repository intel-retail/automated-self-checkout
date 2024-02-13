

from pathlib import Path
from typing import Tuple, Dict
import cv2
import numpy as np
from ultralytics.yolo.utils.plotting import colors
from PIL import Image
from ultralytics import YOLO

models_dir = Path('./models')
models_dir.mkdir(exist_ok=True)

DET_MODEL_NAME = "yolov8n"

det_model = YOLO(models_dir / f'{DET_MODEL_NAME}.pt')
label_map = det_model.model.names


det_model_path = models_dir / f"{DET_MODEL_NAME}.xml"
if not det_model_path.exists():
    det_model.export(format="openvino", dynamic=True, half=False)


