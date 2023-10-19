# Openvino OVMS C-API Pipeline Run

Openvino has [many ways to run inferencing pipeline](https://docs.openvino.ai/2023.1/ovms_docs_server_api.html): 
TensorFlow Serving gRPC API, KServe gRPC API, TensorFlow Serving REST API, KServe REST API and OVMS C API through model server. Here is a demonstration for using OVMS C API method to run face detection inferencing pipeline with steps below:

1. Add new section to model configuration file for model server
2. Add environment variable file dependency
3. add a profile launcher pipeline configuration file
4. build and run


## Add New Section To Model Config File for Model Server
Here is the config file location: `configs/opencv-ovms/models/2022/config_template.json`, edit the file and append the following face detection model configuration section to the template
```json
,
{"config": {
      "name": "face-detection-retail-0005",
      "base_path": "face-detection-retail-0005/FP16-INT8",
      "shape": "(1,3,800,800)",
      "nireq": 2,
      "batch_size":"1",
      "plugin_config": {"PERFORMANCE_HINT": "LATENCY"},
      "target_device": "{target_device}"},
      "latest": { "num_versions": 2 }
    }
```
!!! Note
    `shape` is optional and takes precedence over batch_size, please remove this attribute if you don't know the value for the model.

!!! Note
    Please leave `target_device` value as it is, as the value `{target_device}` will be recognized and filled out by script run.

You can find each parameter description from model server [ovms_docs_parameters](https://docs.openvino.ai/2023.1/ovms_docs_parameters.html).

## Add Environment Variable File
You can add environment variable file to `configs/opencv-ovms/envs/` directory and you can add more than one environment variable file for your pipeline. For face detection pipeline run, we have added `configs/opencv-ovms/envs/capi_face_detection.env`, below is a list of explanation for each environment variable and current default values we set for face detection pipeline run, this list can be extended for any future modification.

| EV Name                   | Description                                           |
| --------------------------| ------------------------------------------------------|
| RENDER_PORTRAIT_MODE      | rendering in portrait mode                            |
| GST_DEBUG                 | GStreamer debug mode option                           |
| USE_ONEVPL                | using OneVPL CPU & GPU Support                        |
| PIPELINE_EXEC_PATH        | pipeline execution path inside container              |
| GST_VAAPI_DRM_DEVICE      | GStreamer VAAP DRM device input                       |
| TARGET_GPU_DEVICE         | target GPU device                                     |
| LOG_LEVEL                 | pipeline run log level option                         |
| RENDER_MODE               | option to display the inferencing result              |
| cl_cache_dir              | cache directory in container                          |

Here is the value we've set so far for capi_face_detection.env
```text
RENDER_PORTRAIT_MODE=0
GST_DEBUG=0
USE_ONEVPL=1
PIPELINE_EXEC_PATH=pipelines/face_detection/face_detection
GST_VAAPI_DRM_DEVICE=/dev/dri/renderD128
TARGET_GPU_DEVICE=--privileged
LOG_LEVEL=0
RENDER_MODE=1
cl_cache_dir=/home/intel/gst-ovms/.cl-cache
```

## Add A Profile Launcher Configuration File
The details about Profile Launcher configuration can be found [here](./profileLauncherConfigs.md), below is detail of capi face detection profile launcher configuration, located at `configs/opencv-ovms/cmd_client/res/capi_face_detection/configuration.yaml`.
```yaml
OvmsSingleContainer: true
OvmsClient:
  DockerLauncher:
    Script: docker-launcher.sh
    DockerImage: openvino/model_server-capi-gst-ovms:latest
    ContainerName: capi_face_detection
    Volumes:
      - "$cl_cache_dir:/home/intel/gst-ovms/.cl-cache"
      - /tmp/.X11-unix:/tmp/.X11-unix
      - "$RUN_PATH/sample-media/:/home/intel/gst-ovms/vids"
      - "$RUN_PATH/configs/opencv-ovms/gst_capi/extensions:/home/intel/gst-ovms/extensions"
      - "$RUN_PATH/results:/tmp/results"
      - "$RUN_PATH/configs/opencv-ovms/models/2022/:/home/intel/gst-ovms/models"
  PipelineScript: ./run_face_detection.sh
  PipelineInputArgs: "" # space delimited like we run the script in command and take those input arguments
  EnvironmentVariableFiles:
    - capi_face_detection.env
```

## Build and Run
1. Build gst-capi ovms with profile-launcher: `make build-gst-capi`
2. Download sample video files: `cd benchmark-scripts/ && ./download_sample_videos.sh && cd ..`
2. Start simulator camera: `./camera-simulator/camera-simulator.sh`
3. To start face detection pipeline: `PIPELINE_PROFILE="capi_face_detection" RENDER_MODE=1 sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --workload ovms`
!!! Note
    The pipeline run will automatically download the Openvino model files listed in `configs/opencv-ovms/models/2022/config_template.json`