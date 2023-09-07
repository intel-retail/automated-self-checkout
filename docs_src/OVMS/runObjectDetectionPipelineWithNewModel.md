# Run Object Detection Pipeline with New Model
For running object detection pipeline, we have defaulted the model to person_vehicle_bike_detection_2000. You can use different model to run object detection. Here are the steps:

1. Add new section to config file for model server
2. Download new model
3. Add new model label file
4. Add architecture type of new model as input to pipeline
5. rebuild containers


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
**_Note:_**  : `shape` is optional and takes precedence over batch_size, please remove this attribute if you don't know the value for the model.
**_Note:_**  : Please leave `target_device` value as it is, as the value `{target_device}` will be recognized and filled out by script run.
**_Note:_**  : Please update value of `name` to your model name
**_Note:_**  : `base_path`: make sure the "yourModelName" is same as the `name` value

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

## Add New Model Label File

