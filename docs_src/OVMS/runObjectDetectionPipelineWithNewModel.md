# Run Object Detection Pipeline with New Model

OpenVINO Model Server has [many ways to run inferencing pipeline](https://docs.openvino.ai/2023.1/ovms_docs_server_api.html):
TensorFlow Serving gRPC API, KServe gRPC API, TensorFlow Serving REST API, KServe REST API and OVMS C API through OpenVINO model server (OVMS). For running object detection pipeline, it is based on KServe gRPC API method, default model used is ssd_mobilenet_v1_coco. You can use different model to run object detection. Here are the steps:

1. Add new section to config file for model server
2. Download new model
3. Update environment variables of detection pipeline for new model
4. Build and Run


## Add New Section to Config File for Model Server

Here is the config file location: `configs/opencv-ovms/models/2022/config_template.json`, edit the file and append the following configuration section template
```json
,
{
      "config": {
        "name": "ssd_mobilenet_v1_coco",
        "base_path": "/models/ssd_mobilenet_v1_coco/FP32",
        "nireq": 1,
        "batch_size": "1",
        "plugin_config": {
          "PERFORMANCE_HINT": "LATENCY"
        },
        "target_device": "{target_device}"
      },
      "latest": {
        "num_versions": 1
      }
    }
```
!!! Note
    Please leave `target_device` value as it is, as the value `{target_device}` will be recognized and replaced by script run.

You can find the parameter description in the [ovms docs](https://docs.openvino.ai/2023.1/ovms_docs_parameters.html).

## Download New Model

The pipeline run script automatically download the model files if it is part of [open model zoo supported list](https://github.com/openvinotoolkit/open_model_zoo/blob/master/demos/object_detection_demo/python/models.lst); otherwise, please add your model files manually to `configs/opencv-ovms/models/2022/`. When you add your model manually, make sure to follow the model file structure as <model_name>/<Precision>/1/modelfiles, for example:

```text
ssd_mobilenet_v1_coco
├── FP32
   └── 1
       ├── ssd_mobilenet_v1_coco.bin
       └── ssd_mobilenet_v1_coco.xml
```

## Update Environment Variables

You can update the object detection environment variables in file: `configs/opencv-ovms/envs/object_detection.env`, here is default value and explanation for each environment variable:

| EV Name                           | Default Value               | Description                                            |
| ----------------------------------| ----------------------------| -------------------------------------------------------|
| DETECTION_MODEL_NAME              | ssd_mobilenet_v1_coco       | model name for object detection                        |
| DETECTION_LABEL_FILE              | coco_91cl_bkgr.txt          | label file name to use on object detection for model   |
| DETECTION_ARCHITECTURE_TYPE       | ssd                         | architecture type for object detection model           |
| DETECTION_OUTPUT_RESOLUTION       | 1280x720                    | output resolution for object detection result          |
| DETECTION_THRESHOLD               | 0.50                        | threshold for object detection                         |
| MQTT                              |                             | enable MQTT notification of result, value: empty|1|0  (Example value: 127.0.0.1:1883) |
| RENDER_MODE                       | 1                           | display the input source video stream with the inferencing results, value: 0|1  |

## Build and Run Pipeline

1. Build the python app and profile-launcher: `make build-python-apps`
2. Download sample video files: `cd benchmark-scripts/ && ./download_sample_videos.sh && cd ..`
3. Start simulator camera if not started: `make run-camera-simulator`
4. (Optional) Run MQTT broker: `docker run --network host --rm -d -it -p 1883:1883 -p 9001:9001 eclipse-mosquitto`
5. To start object detection pipeline: `PIPELINE_PROFILE="object_detection" RENDER_MODE=1 MQTT=127.0.0.1:1883 sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --workload ovms` (remove the MQTT environment variable if not using it)
6. If do use MQTT, use the container name as the MQTT topic to subscribe to the inference metadata. Do a `docker ps` to know the container name.
7. To stop the running pipelines: `make clean-profile-launcher` to stop and clean up the client side containers, or `make clean-all` to stop and clean up everything.