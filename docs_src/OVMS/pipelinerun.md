# Customized Run Pipeline

## Overview 
When the pipeline is run, the `run.sh` script starts the service and performs inferencing on the selected input media. The output of running the pipeline provides the inference results for each frame based on the media source such as text, barcode, and so on, as well as the frames per second (FPS). Pipeline run provides many options in media type, system process platform type, and additional optional parameters. These options give you the opportunity to compare what system process platform is better for your need.

## Start Pipeline
You can run the pipeline script, `run.sh` with a given pipeline profile via the environment variable `PIPELINE_PROFILE`, and the following additional input parameters:

1. Media type
    - Camera Simulator running [using RTSP](../dev-tools/run_camera_simulator.md)
    - USB Camera using a [supported output format](../query_usb_camera.md)
    - Real Sense Camera using the [serial number](./camera_serial_number.md)
    - Video File
2. Platform
    - core
    - dgpu.0
    - dgpu.1
    - xeon
3. [Environment Variables](../dev-tools/environment_variables.md)
 
Run the command based on your requirement. Once choices are selected for #1-3 above, to start the pipeline run, use the commands from the [Examples](#run-pipeline-with-different-input-sourceinputsrc-types) section below.

## Examples using different input source types
In the following examples, [environment variables](../dev-tools/environment_variables.md) are used to select the desired `PIPELINE_PROFILE` and `RENDER_MODE`. This table uses `run.sh` to run the object_detection pipeline profile:

| Input source Type  | Input Source Parameter                | Command                                                                                                                                                              |          
|---------------------|---------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Simulated camera   | `rtsp://127.0.0.1:8554/camera_X`      | <code>PIPELINE_PROFILE="object_detection" RENDER_MODE=1 sudo -E ./run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc rtsp://127.0.0.1:8554/camera_1</code>      |
| RealSense camera   | `<serial_number> --realsense_enabled` | <code>PIPELINE_PROFILE="object_detection" RENDER_MODE=1 sudo -E ./run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc <serial_number> --realsense_enabled</code> |
| USB camera         | `/dev/video0`                         | <code>PIPELINE_PROFILE="object_detection" RENDER_MODE=1 sudo -E ./run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc /dev/video0</code>                         |
| Video file         | `file:my_video_file.mp4`              | <code>PIPELINE_PROFILE="object_detection" RENDER_MODE=1 sudo -E ./run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc file:my_video_file.mp4</code>              |


!!! Note
    The value of x in `dgpu.x` can be 0, 1, 2, and so on depending on the number of discrete GPUs in the system.
