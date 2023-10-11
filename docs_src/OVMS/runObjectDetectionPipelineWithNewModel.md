# Run Object Detection Pipeline with New Model
For running object detection pipeline, we have defaulted the model to person_vehicle_bike_detection_2000. You can use different model to run object detection. Here are the steps:

1. Add new section to config file for model server
2. Download new model
3. Update environment variables of detection pipeline for new model
4. rebuild containers


## Add New Section to Config File for Model Server
Here is the config file location: `configs/opencv-ovms/models/2022/config_template.json`, edit the file and append the following configuration section template
```json
,
{"config": {
                "name": "yourModelName",
                "base_path": "/models/yourModelName/FP16-INT8",
                "nireq": 1,
                "batch_size":"1",
                "shape": "(1,608,608,3)",
                "layout": "NHWC:NCHW",
                "plugin_config": {"PERFORMANCE_HINT": "LATENCY"},
                "target_device": "{target_device}"},
                "latest": { "num_versions": 1 }
        }
```
!!! Note
    `shape` is optional and takes precedence over batch_size, please remove this attribute if you don't know the value for the model.

!!! Note
    Please leave `target_device` value as it is, as the value `{target_device}` will be recognized and filled out by script run.

!!! Note
    Please update value of `name` to your model name

!!! Note
    `base_path`: make sure the "yourModelName" is same as the `name` value

You can find each parameter description from model server [ovms_docs_parameters](https://docs.openvino.ai/2023.0/ovms_docs_parameters.html).

## Download New Model
The pipeline run script automatically download the model files if it is part of [open model zoo supported list](https://github.com/openvinotoolkit/open_model_zoo/blob/master/demos/object_detection_demo/python/models.lst); otherwise, please add your model files manually to `configs/opencv-ovms/models/2022/`. When you add your model manually, make sure to follow the model file structure as <model_name>/<Precision>/1/modelfiles, for example:

```text
instance-segmentation-security-1040
│   └── FP16-INT8
│       └── 1
│           ├── instance-segmentation-security-1040.bin
│           └── instance-segmentation-security-1040.xml
```

## Update Environment Variables
You can update the object detection environment variables in file: `configs/opencv-ovms/envs/object_detection.env`, here is explanation for each environment variable:

| EV Name                           | Description                                           |
| ----------------------------------| ------------------------------------------------------|
| DETECTION_MODEL_NAME              | model name for object detection                       |
| DETECTION_LABEL_FILE              | label file name to use on object detection for model  |
| DETECTION_ARCHITECTURE_TYPE       | architecture type for object detection model          |
| DETECTION_OUTPUT_RESOLUTION       | output resolution for object detection result         |
| DETECTION_THRESHOLD               | threshold for object detection                        |

Here is an sample content for object_detection.env
```text
DETECTION_MODEL_NAME=yourModelName
DETECTION_LABEL_FILE=yourModelLabelfile.txt
DETECTION_ARCHITECTURE_TYPE=ssd
DETECTION_OUTPUT_RESOLUTION=1280x720
DETECTION_THRESHOLD=0.50
```

## Rebuild and Run Pipeline
1. Rebuild the python app and profile-launcher: `make build-python-apps`
2. Restart simulator camera if not started: `./camera-simulator/camera-simulator.sh`
3. To start object detection pipeline: `PIPELINE_PROFILE="object_detection" RENDER_MODE=1 sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --workload ovms`