


import os
import threading
import time
import urllib.parse
from os import PathLike
from pathlib import Path
from typing import List, NamedTuple, Optional, Tuple

import numpy as np
from openvino.runtime import Core, get_version
from zipfile import ZipFile
from tqdm import tqdm

import nncf  # noqa: F811
from typing import Dict


from ultralytics.yolo.utils import DEFAULT_CFG
from ultralytics.yolo.cfg import get_cfg
from ultralytics.yolo.data.utils import check_det_dataset
import openvino as ov

#from pathlib import Path
#from typing import Tuple, Dict
#import cv2
import numpy as np
from ultralytics.yolo.utils.plotting import colors
from PIL import Image
from ultralytics.yolo.utils import ops
import torch
from ultralytics import YOLO



def download_file(
    url: PathLike,
    filename: PathLike = None,
    directory: PathLike = None,
    show_progress: bool = True,
    silent: bool = False,
    timeout: int = 65000,
) -> PathLike:
    """
    Download a file from a url and save it to the local filesystem. The file is saved to the
    current directory by default, or to `directory` if specified. If a filename is not given,
    the filename of the URL will be used.

    :param url: URL that points to the file to download
    :param filename: Name of the local file to save. Should point to the name of the file only,
                     not the full path. If None the filename from the url will be used
    :param directory: Directory to save the file to. Will be created if it doesn't exist
                      If None the file will be saved to the current working directory
    :param show_progress: If True, show an TQDM ProgressBar
    :param silent: If True, do not print a message if the file already exists
    :param timeout: Number of seconds before cancelling the connection attempt
    :return: path to downloaded file
    """
    from tqdm.notebook import tqdm_notebook
    import requests

    filename = filename or Path(urllib.parse.urlparse(url).path).name
    chunk_size = 16384  # make chunks bigger 

    filename = Path(filename)
    if len(filename.parts) > 1:
        raise ValueError(
            "`filename` should refer to the name of the file, excluding the directory. "
            "Use the `directory` parameter to specify a target directory for the downloaded file."
        )

    # create the directory if it does not exist, and add the directory to the filename
    if directory is not None:
        directory = Path(directory)
        directory.mkdir(parents=True, exist_ok=True)
        filename = directory / Path(filename)

    try:
        response = requests.get(url=url,
                                headers={"User-agent": "Mozilla/5.0"},
                                stream=True)
        response.raise_for_status()
    except requests.exceptions.HTTPError as error:  # For error associated with not-200 codes. Will output something like: "404 Client Error: Not Found for url: {url}"
        raise Exception(error) from None
    except requests.exceptions.Timeout:
        raise Exception(
                "Connection timed out. If you access the internet through a proxy server, please "
                "make sure the proxy is set in the shell from where you launched Jupyter."
        ) from None
    except requests.exceptions.RequestException as error:
        raise Exception(f"File downloading failed with error: {error}") from None

    # download the file if it does not exist, or if it exists with an incorrect file size
    filesize = int(response.headers.get("Content-length", 0))
    if not filename.exists() or (os.stat(filename).st_size != filesize):

#        with tqdm_notebook(
#            total=filesize,
#            unit="B",
#            unit_scale=True,
#            unit_divisor=1024,
#            desc=str(filename),
#            disable=not show_progress,
#        ) as progress_bar:

#            with open(filename, "wb") as file_object:
#                for chunk in response.iter_content(chunk_size):
#                    file_object.write(chunk)
#                    progress_bar.update(len(chunk))
#                    progress_bar.refresh()
#    else:
#        if not silent:
#            print(f"'{filename}' already exists.")

        with tqdm(range(filesize),unit="B", 
                unit_scale=True,
                unit_divisor=1024,
                desc=str(filename)) as progress_bar:
            with open(filename, "wb") as file_object:
                for chunk in response.iter_content(chunk_size):
                    file_object.write(chunk)
                    progress_bar.update(len(chunk))
                    progress_bar.refresh()
    else:
        printf(f"'{filename}' already exists.")

    response.close()

    return filename.resolve()


DATA_URL = "http://images.cocodataset.org/zips/val2017.zip"
LABELS_URL = "https://github.com/ultralytics/yolov5/releases/download/v1.0/coco2017labels-segments.zip"
CFG_URL = "https://raw.githubusercontent.com/ultralytics/ultralytics/8ebe94d1e928687feaa1fee6d5668987df5e43be/ultralytics/datasets/coco.yaml"

OUT_DIR = Path('./datasets')

DATA_PATH = OUT_DIR / "val2017.zip"
LABELS_PATH = OUT_DIR / "coco2017labels-segments.zip"
CFG_PATH = OUT_DIR / "coco.yaml"

if not (DATA_PATH).exists(): 
    download_file(DATA_URL, DATA_PATH.name, DATA_PATH.parent)
if not (LABELS_PATH).exists():
    download_file(LABELS_URL, LABELS_PATH.name, LABELS_PATH.parent)
if not (CFG_PATH).exists():
    download_file(CFG_URL, CFG_PATH.name, CFG_PATH.parent)

if not (OUT_DIR / "coco/labels").exists():
    with ZipFile(LABELS_PATH , "r") as zip_ref:
        zip_ref.extractall(OUT_DIR)
    with ZipFile(DATA_PATH , "r") as zip_ref:
        zip_ref.extractall(OUT_DIR / 'coco/images')

def transform_fn(data_item:Dict):
    """
    Quantization transform function. Extracts and preprocess input data from dataloader item for quantization.
    Parameters:
       data_item: Dict with data item produced by DataLoader during iteration
    Returns:
        input_tensor: Input data for quantization
    """
    input_tensor = det_validator.preprocess(data_item)['img'].numpy()
    return input_tensor


args = get_cfg(cfg=DEFAULT_CFG)
args.data = str(CFG_PATH)
#args.imgsz = 416

models_dir = Path('./models')
models_dir.mkdir(exist_ok=True)
DET_MODEL_NAME = "yolov8n"
det_model = YOLO(models_dir / f'{DET_MODEL_NAME}.pt')
#det_model.imgsz = 416

det_validator = det_model.ValidatorClass(args=args)
det_validator.data = check_det_dataset(args.data)
det_data_loader = det_validator.get_dataloader("datasets/coco", 1)

det_validator.is_coco = True
det_validator.class_map = ops.coco80_to_coco91_class()
det_validator.names = det_model.model.names
det_validator.metrics.names = det_validator.names
det_validator.nc = det_model.model.model[-1].nc


##
#from tqdm.notebook import tqdm
from ultralytics.yolo.utils.metrics import ConfusionMatrix


def test(model:ov.Model, core:ov.Core, data_loader:torch.utils.data.DataLoader, validator, num_samples:int = None):
    """
    OpenVINO YOLOv8 model accuracy validation function. Runs model validation on dataset and returns metrics
    Parameters:
        model (Model): OpenVINO model
        data_loader (torch.utils.data.DataLoader): dataset loader
        validator: instance of validator class
        num_samples (int, *optional*, None): validate model only on specified number samples, if provided
    Returns:
        stats: (Dict[str, float]) - dictionary with aggregated accuracy metrics statistics, key is metric name, value is metric value
    """
    validator.seen = 0
    validator.jdict = []
    validator.stats = []
    validator.batch_i = 1
    validator.confusion_matrix = ConfusionMatrix(nc=validator.nc)
    model.reshape({0: [1, 3, -1, -1]})
    compiled_model = core.compile_model(model)
    for batch_i, batch in enumerate(tqdm(data_loader, total=num_samples)):
        if num_samples is not None and batch_i == num_samples:
            break
        batch = validator.preprocess(batch)
        results = compiled_model(batch["img"])
        preds = torch.from_numpy(results[compiled_model.output(0)])
        preds = validator.postprocess(preds)
        validator.update_metrics(preds, batch)
    stats = validator.get_stats()
    return stats


def print_stats(stats:np.ndarray, total_images:int, total_objects:int):
    """
    Helper function for printing accuracy statistic
    Parameters:
        stats: (Dict[str, float]) - dictionary with aggregated accuracy metrics statistics, key is metric name, value is metric value
        total_images (int) -  number of evaluated images
        total objects (int)
    Returns:
        None
    """
    print("Boxes:")
    mp, mr, map50, mean_ap = stats['metrics/precision(B)'], stats['metrics/recall(B)'], stats['metrics/mAP50(B)'], stats['metrics/mAP50-95(B)']
    # Print results
    s = ('%20s' + '%12s' * 6) % ('Class', 'Images', 'Labels', 'Precision', 'Recall', 'mAP@.5', 'mAP@.5:.95')
    print(s)
    pf = '%20s' + '%12i' * 2 + '%12.3g' * 4  # print format
    print(pf % ('all', total_images, total_objects, mp, mr, map50, mean_ap))
    if 'metrics/precision(M)' in stats:
        s_mp, s_mr, s_map50, s_mean_ap = stats['metrics/precision(M)'], stats['metrics/recall(M)'], stats['metrics/mAP50(M)'], stats['metrics/mAP50-95(M)']
        # Print results
        s = ('%20s' + '%12s' * 6) % ('Class', 'Images', 'Labels', 'Precision', 'Recall', 'mAP@.5', 'mAP@.5:.95')
        print(s)
        pf = '%20s' + '%12i' * 2 + '%12.3g' * 4  # print format
        print(pf % ('all', total_images, total_objects, s_mp, s_mr, s_map50, s_mean_ap))


#NUM_TEST_SAMPLES = 300
#fp_det_stats = test(det_ov_model, core, det_data_loader, det_validator, num_samples=NUM_TEST_SAMPLES)
#print_stats(fp_det_stats, det_validator.seen, det_validator.nt_per_class.sum())
##



#det_validator.imgsz = 416

quantization_dataset = nncf.Dataset(det_data_loader, transform_fn)

# Ignored nodes with name ['/model.22/Add_7', '/model.22/Add_4', '/model.22/Add_6', '/model.22/Add_3', '/model.22/Add_10', '/model.22/Add_8', '/model.22/Add_9', '/model.22/Add_5']
#iignored_scope = nncf.IgnoredScope(
#    types=["Multiply", "Subtract", "Sigmoid"],  # ignore operations
#    names=[
#        "/model.22/dfl/conv/Conv",           # in the post-processing subgraph
#        "/model.22/Add",
#        "/model.22/Add_1",
#        "/model.22/Add_2"
#    ]
#)

ignored_scope = nncf.IgnoredScope(
    types=["Multiply", "Subtract", "Sigmoid"],  # ignore operations
    names=[
        "/model.22/dfl/conv/Conv",           # in the post-processing subgraph
        "/model.22/Add",
        "/model.22/Add_1",
        "/model.22/Add_2",
        "/model.22/Add_3",
        "/model.22/Add_4",
        "/model.22/Add_5",
        "/model.22/Add_6",
        "/model.22/Add_7",
        "/model.22/Add_8",
        "/model.22/Add_9",
        "/model.22/Add_10"
    ]
)



# Detection model
core = ov.Core()
det_model_path = "./yolov8n-fp32-416.xml"
det_ov_model = core.read_model(det_model_path)
det_ov_model.reshape({0: [1, 3, 640, 640]})
det_compiled_model = core.compile_model(det_ov_model, "CPU")

NUM_TEST_SAMPLES = 300
fp_det_stats = test(det_ov_model, core, det_data_loader, det_validator, num_samples=NUM_TEST_SAMPLES)
print_stats(fp_det_stats, det_validator.seen, det_validator.nt_per_class.sum())





quantized_det_model = nncf.quantize(
    det_ov_model,
    quantization_dataset,
    preset=nncf.QuantizationPreset.MIXED,
    ignored_scope=ignored_scope
)

quantized_det_model.reshape({0: [1, 3, 640, 640]})

int8_det_stats = test(quantized_det_model, core, det_data_loader, det_validator, num_samples=NUM_TEST_SAMPLES)
print("FP32 model accuracy")
print_stats(fp_det_stats, det_validator.seen, det_validator.nt_per_class.sum())
print("INT8 model accuracy")
print_stats(int8_det_stats, det_validator.seen, det_validator.nt_per_class.sum())

print("Build-in prrocessing")
from openvino.preprocess import PrePostProcessor
ppp = PrePostProcessor(quantized_det_model)

# orig tutorial
#ppp.input(0).tensor().set_shape([1, 640, 640, 3]).set_element_type(ov.Type.u8).set_layout(ov.Layout('NHWC'))
#ppp.input(0).preprocess().convert_element_type(ov.Type.f32).convert_layout(ov.Layout('NCHW')).scale([255., 255., 255.])

ppp.input(0).tensor().set_shape([1, 3, 416,416]).set_layout(ov.Layout('NCHW'))
ppp.input(0).preprocess().convert_element_type(ov.Type.f32).scale([255., 255., 255.])

print(ppp)

quantized_pp_model = ppp.build()

from openvino.runtime import serialize
int8_model_det_path = f'./yolov8n-int8-416.xml'
print(f"Quantized detection model will be saved to {int8_model_det_path}")
#serialize(quantized_det_model, str(int8_model_det_path))
serialize(quantized_pp_model, str(int8_model_det_path))

