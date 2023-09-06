# Run Object Detection Pipeline with New Model
For running object detection pipeline, we have defaulted the model to person_vehicle_bike_detection_2000. You can use different model to run object detection. Here are the steps:

1. Add new section to config file for model server
2. Download new model
3. Add new model label file
4. Add architecture type of new model as input to pipeline
5. rebuild containers


## Add New Section to Config File for Model Server
Here is the config file location: `configs/opencv-ovms/models/2022/config.json`, edit the file and append following configuration section template
```json
,
{"config": {
                "name": "modelName",
                "base_path": "/models/modelName/FP16-INT8",
                "nireq": 1,
                "batch_size":"1",
		        "shape": "auto",
                "layout": "NHWC:NCHW",
                "plugin_config": {"PERFORMANCE_HINT": "LATENCY"},
                "target_device": "CPU"},
                "latest": { "num_versions": 1 }
        }
```
You will need to replace new model name on "modelName" above, make sure to fill out details for each parameter, you can find each parameter description from model server [ovms_docs_parameters](https://docs.openvino.ai/2023.0/ovms_docs_parameters.html)

## Download New Model
The pipeline run script automatically download the model files if it is part of [open model zoo supported list](https://github.com/openvinotoolkit/open_model_zoo/blob/master/demos/object_detection_demo/python/models.lst); otherwise, please add your model files manually to `configs/opencv-ovms/models/2022/`.

## Add New Model Label File

