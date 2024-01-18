# OpenVINO OVMS C-API Pipeline Run

OpenVINO Model Server has [many ways to run inferencing pipeline](https://docs.openvino.ai/2023.1/ovms_docs_server_api.html):
TensorFlow Serving gRPC API, KServe gRPC API, TensorFlow Serving REST API, KServe REST API and OVMS C API through OpenVINO model server (OVMS). Here is a demonstration for using OVMS C API method to run face detection inferencing pipeline with steps below:

1. Add new section to model configuration file for model server
2. Add pipeline specific files
3. Add environment variable file dependency
4. Add a profile launcher pipeline configuration file
5. Build and run


## Add New Section To Model Config File for Model Server

Here is the template config file location: `configs/opencv-ovms/models/2022/config_template.json`, edit the file and append the following face detection model configuration section to the template
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
    Please leave `target_device` value as it is, as the value `{target_device}` will be recognized and replaced by script run.

You can find the parameter description in the [ovms docs](https://docs.openvino.ai/2023.1/ovms_docs_parameters.html).

## Add pipeline specific files

Here is the list of files we added in directory of `configs/opencv-ovms/gst_capi/pipelines/face_detection/`:

1. `main.cpp` - this is all the work about pre-processing before sending to OVMS for inferencing and post-processing for displaying.
2. `Makefile` - to help building the pre-processing and post-processing binary.

## Add Environment Variable File

You can add multiple environment variable files to `configs/opencv-ovms/envs/` directory for your pipeline. For face detection pipeline run, we have added `configs/opencv-ovms/envs/capi_face_detection.env` environment variable file. Below is a list of explanation for all environment variables and current default values we set for face detection pipeline run, this list can be extended for any future modification.

| EV Name                   |Face Detection Default Value             | Description                                           |
| --------------------------|-----------------------------------------|-------------------------------------------------------|
| RENDER_PORTRAIT_MODE      | 1                                       | rendering in portrait mode, value: 0 or 1              |
| GST_DEBUG                 | 1                                       | running GStreamer in debug mode, value: 0 or 1         |
| USE_ONEVPL                | 1                                       | using OneVPL CPU & GPU Support, value: 0 or 1          |
| PIPELINE_EXEC_PATH        | pipelines/face_detection/face_detection | pipeline execution path inside container               |
| GST_VAAPI_DRM_DEVICE      | /dev/dri/renderD128                     | GStreamer VAAPI DRM device input                       |
| TARGET_GPU_DEVICE         | --privileged                            | allow using GPU devices if any                         |
| LOG_LEVEL                 | 0                                       | [GST_DEBUG log level](https://gstreamer.freedesktop.org/documentation/tutorials/basic/debugging-tools.html?gi-language=c#the-debug-log) to be set when running gst pipeline         |
| RENDER_MODE               | 1                                       | option to display the input source video stream with the inferencing results, value: 0 or 1              |
| cl_cache_dir              | /home/intel/gst-ovms/.cl-cache          | cache directory in container                          |
| WINDOW_WIDTH              | 1920                                    | display window width                                  |
| WINDOW_HEIGHT             | 1080                                    | display window height                                 |
| DETECTION_THRESHOLD       | 0.9                                     | detection threshold value in floating point that needs to be between 0.0 to 1.0 |

!!! Note
    Details of the face detection pipeline environment variable file can be viewed in [`configs/opencv-ovms/envs/capi_face_detection.env`](https://github.com/intel-retail/automated-self-checkout/blob/main/configs/opencv-ovms/envs/capi_face_detection.env).

## Add A Profile Launcher Configuration File

The details about Profile Launcher configuration can be found [here](./profileLauncherConfigs.md), and the details of capi face detection profile launcher configuration can be viewed in [`configs/opencv-ovms/cmd_client/res/capi_face_detection/configuration.yaml`](https://github.com/intel-retail/automated-self-checkout/blob/main/configs/opencv-ovms/cmd_client/res/capi_face_detection/configuration.yaml).


## Build and Run

Here are the quick start steps to build and run OVMS C API face detection pipeline profile:

1. Build gst-capi ovms with profile-launcher: 

    ```bash
    make build-capi_face_detection
    ```

2. Download sample video files: 

    ```bash
    cd benchmark-scripts/ && ./download_sample_videos.sh && cd ..
    ```

3. Start simulator camera: 
   
    ```bash
    make run-camera-simulator
    ```

4. To start face detection pipeline:

    ```bash
    PIPELINE_PROFILE="capi_face_detection" RENDER_MODE=1 sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0. 1:8554/camera_0
    ```

    !!! Note
        The pipeline run will automatically download the OpenVINO model files listed in `configs/opencv-ovms/models/2022/config_template.json`