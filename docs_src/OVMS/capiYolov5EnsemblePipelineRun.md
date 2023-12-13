# OpenVINO OVMS C-API Yolov5 Ensemble Pipeline Run

OpenVINO Model Server has [many ways to run inferencing pipeline](https://docs.openvino.ai/2023.1/ovms_docs_server_api.html):
TensorFlow Serving gRPC API, KServe gRPC API, TensorFlow Serving REST API, KServe REST API and OVMS C API through OpenVINO model server (OVMS). Here we are demonstrating for using OVMS C API method to run inferencing pipeline yolov5s ensemble models in following steps:

1. Add new section to model configuration file for model server
2. Add pipeline specific files
3. Add environment variable file dependency
4. Add a profile launcher pipeline configuration file
5. Build and run
6. Clean up


## Add New Section To Model Config File for Model Server

The model template configuration file has been updated with model configs of yolov5, efficientnetb0_FP32INT8 and custom configurations, please view [`configs/opencv-ovms/models/2022/config_template.json`](https://github.com/intel-retail/automated-self-checkout/blob/main/configs/opencv-ovms/models/2022/config_template.json) for detail.
!!! Note
    New model yolov5 is similar to yolov5s configuration except the layout difference.

!!! Note
    The model efficientnetb0_FP32INT8 is different model from efficientnet-b0.


## Add pipeline specific files

The pre-processing and post-processing work files are added in directory of [`configs/opencv-ovms/gst_capi/pipelines/capi_yolov5_ensemble/`](https://github.com/intel-retail/automated-self-checkout/blob/main/configs/opencv-ovms/gst_capi/pipelines/capi_yolov5_ensemble/), please view directory for details.

## Add Environment Variable File

You can add multiple environment variable files to `configs/opencv-ovms/envs/` directory for your pipeline, we've added `capi_yolov5_ensemble.env` for yolov5 ensemble pipeline run. Below is a list of explanation for all environment variables and current default values we set, this list can be extended for any future modification.

| EV Name                   |Default Value                                        | Description                                           |
| --------------------------|-----------------------------------------------------|-------------------------------------------------------|
| RENDER_PORTRAIT_MODE      | 1                                                   | rendering in portrait mode, value: 0 or 1             |
| GST_DEBUG                 | 1                                                   | running GStreamer in debug mode, value: 0 or 1        |
| USE_ONEVPL                | 1                                                   | using OneVPL CPU & GPU Support, value: 0 or 1         |
| PIPELINE_EXEC_PATH        | pipelines/capi_yolov5_ensemble/capi_yolov5_ensemble | pipeline execution path inside container              |
| GST_VAAPI_DRM_DEVICE      | /dev/dri/renderD128                                 | GStreamer VAAPI DRM device input                      |
| TARGET_GPU_DEVICE         | --privileged                                        | allow using GPU devices if any                        |
| LOG_LEVEL                 | 0                                                   | [GST_DEBUG log level](https://gstreamer.freedesktop.org/documentation/tutorials/basic/debugging-tools.html?gi-language=c#the-debug-log) to be set when running gst pipeline |
| RENDER_MODE               | 1                                                   | option to display the input source video stream with the inferencing results, value: 0 or 1              |
| cl_cache_dir              | /home/intel/gst-ovms/.cl-cache                      | cache directory in container                          |
| WINDOW_WIDTH              | 1920                                                | display window width                                  |
| WINDOW_HEIGHT             | 1080                                                | display window height                                 |
| DETECTION_THRESHOLD       | 0.7                                                 | detection threshold value in floating point that needs to be between 0.0 to 1.0 |
| BARCODE                   | 1                                                   | For capi_yolov5_ensemble pipeline, you can enable barcode detection. value: 0 or 1 |

details of yolov5s pipeline environment variable file can be viewed in [`configs/opencv-ovms/envs/capi_yolov5_ensemble.env`](https://github.com/intel-retail/automated-self-checkout/blob/main/configs/opencv-ovms/envs/capi_yolov5_ensemble.env).

## Add A Profile Launcher Configuration File

The details about Profile Launcher configuration can be found [here](./profileLauncherConfigs.md), details for yolov5 pipeline profile launcher configuration can be viewed in [`configs/opencv-ovms/cmd_client/res/capi_yolov5_ensemble/configuration.yaml`](https://github.com/intel-retail/automated-self-checkout/tree/main/configs/opencv-ovms/cmd_client/res/capi_yolov5_ensemble/configuration.yaml)

## Build and Run

Here are the quick start steps to build and run capi yolov5 pipeline profile :

1. Build docker image with profile-launcher: `make build-capi_yolov5_ensemble`
2. Download sample video files: `cd benchmark-scripts/ && ./download_sample_videos.sh && cd ..`
3. Start simulator camera: `make run-camera-simulator`
4. To start the pipeline run: `PIPELINE_PROFILE="capi_yolov5_ensemble" RENDER_MODE=1 sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0`
!!! Note
    The pipeline will automatically download the OpenVINO model files listed in [`configs/opencv-ovms/models/2022/config_template.json`](https://github.com/intel-retail/automated-self-checkout/blob/main/configs/opencv-ovms/models/2022/config_template.json)

# Clean Up

To stop existing container: `make clean-capi_yolov5_ensemble`
To stop all running containers including camera simulator and remove all log files: `make clean-all`