# Customize Run

## Overview 
When the pipeline is run, the `run.sh` script starts the service and performs inferencing on the selected input media. The output of running the pipeline provides the inference results for each frame based on the media source such as text, barcode, and so on, as well as the frames per second (FPS). Pipeline run provides many options in media type, system process platform type, and additional optional parameters. These options give you the opportunity to compare what system process platform is better for your need.

## Start Pipeline
You can run the pipeline script, `run.sh` with a given pipeline profile via the environment variable `PIPELINE_PROFILE`, and the following additional input parameters:

1. Media type
    - Camera Simulator using RTSF
    - USB Camera
    - Video File
2. Platform
    - core
    - dgpu.0
    - dgpu.1
    - xeon
3. [Environment Variables](../dev-tools/environment_variables.md)
 
Run the command based on your requirement. You have to get your choices for #1-4 above to start the pipeline run, see [details](#run-pipeline-with-different-input-sourceinputsrc-types) section below.


### Environment variables
When running run.sh script, we support environment variables as input for containers. [Here is a list of environment variables and how to apply them](../dev-tools/environment_variables.md)

Here is an example on how to run `instance segmentation` pipelines via applying environment variables:

```console
PIPELINE_PROFILE="instance_segmentation" RENDER_MODE=1 sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
```

## Run pipeline with different input source (inputsrc) types
Use run.sh to run the pipeline, here is the table of basic scripts for each combination:

| Input source Type |Command                                                                                                                                        |          
|-------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Simulated camera  | <code>sudo ./run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc rtsp://127.0.0.1:8554/camera_0</code>      |
| RealSense camera  | <code>sudo ./run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc <serial_number> --realsense_enabled</code> |
| USB camera        | <code>sudo ./run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc /dev/video0</code>                         |
| Video file      | <code>sudo ./run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc file:my_video_file.mp4</code>              |

!!! Note
    For simulated camera as input source, please [run camera simulator first](../dev-tools/run_camera_simulator.md).

!!! Note
    For using RealSense as input source, please [see here on how to obtain serial number](./camera_serial_number.md).

!!! Note
    The value of x in `dgpu.x` can be 0, 1, 2, and so on depending on the number of discrete GPUs in the system.
    
!!! Note
    Follow these [steps](../query_usb_camera.md) to see the output formats supported by your USB camera.


### Supporting different programming languages for OVMS grpc client
We are supporting multiple programming languages for OVMS grpc client. Currently we are supporting grpc-python and grpc-go. The scripts to start pipelines above would start grpc-python as default. [See more on supporting different language](./supportingDifferentLanguage.md)

### Supporting different models for OVMS grpc python client
With OVMS grpc-python client, you can configure to use different model to run the inferencing pipeline. The scripts to start pipelines above would start grpc-python using `instance-segmentation-security-1040` model as default. [See more on supporting different model](./supportingDifferentModel.md)


## Stop pipeline run
You can call `make clean-ovms` to stop the pipeline and all running containers for ovms, hence the results directory log files will stop growing. Below is the table of make commands you can call to clean things up per your needs:

| Clean Containers Options                                     | Command                            |
| -------------------------------------------------------------| -----------------------------------|
| clean instance-segmentation container if any                 | <pre>make clean-segmentation</pre>      |
| clean grpc-go dev container if any                           | <pre>make clean-grpc-go</pre>      |
| clean all related containers launched by profile-launcher if any | <pre>make clean-profile-launcher</pre>  |
| clean ovms-server container                                 | <pre>make clean-ovms-server</pre> |
| clean ovms-server and all containers launched by profile-launcher          | <pre>make clean-ovms</pre>         |
| clean results/ folder                                        | <pre>make clean-results</pre>      |
