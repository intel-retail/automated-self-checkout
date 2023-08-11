# Run Pipeline

## Prerequisites 
Before running, [set up the pipeline](./pipelinesetup.md).

---
## Overview 
When the pipeline is run, the `docker-run.sh` script starts the service and performs inferencing on the selected input media. The output of running the pipeline provides the inference results for each frame based on the media source such as text, barcode, and so on, as well as the frames per second (FPS). Pipeline run provides many options in media type, system process platform type, and additional optional parameters. These options give you the opportunity to compare what system process platform is better for your need.

## Start Pipeline
You can run the pipeline script, `docker-run.sh` with `--workload opencv-ovms` option, and the following additional input parameters:

1. Media type
    - Camera Simulator using RTSF
    - USB Camera
    - Video File
2. Platform
    - core
    - dgpu.0
    - dgpu.1
    - xeon
3. [Optional parameters](#optional-parameters)
 
Run the command based on your requirement. You have to get your choices for #1, #2, #3 above to start the pipeline run, see [details](#run-pipeline-with-different-input-sourceinputsrc-types) section below.

### Check successful pipeline run
Once pipeline run has started, you will expect containers to be running, see [check for pipeline run success](#status-of-running-a-pipeline); For a successful run, see [sample output results](#sample-output).

### Stop pipeline run
You can call `make clean-ovms` to stop the pipeline and all running containers for opencv-ovms, hence the results directory log files will stop growing. Below is the table of make commands you can call to clean things up per your needs:

| Clean Containers Options                                     | Command                            |
| -------------------------------------------------------------| -----------------------------------|
| clean grpc-go dev container if any                           | <pre>make clean-grpc-go</pre>      |
| clean ovms-client container and grpc-go dev container if any | <pre>make clean-ovms-client</pre>  |
| clean model-server container                                 | <pre>make clean-model-server</pre> |
| clean both ovms-client and model-server containers           | <pre>make clean-ovms</pre>         |
| clean results/ folder                                        | <pre>make clean-results</pre>      |

---

## Run pipeline with different input source(inputsrc) types
Use docker-run.sh to run the pipeline, here is the table of basic scripts for each combination:
| Input source Type |Command                                                                                                                                        |          
|-------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Simulated camera  | <code>sudo ./docker-run.sh --workload opencv-ovms --platform core&#124;xeon&#124;dgpu.x --inputsrc rtsp://127.0.0.1:8554/camera_0</code>      |
| Realsense camera  | <code>sudo ./docker-run.sh --workload opencv-ovms --platform core&#124;xeon&#124;dgpu.x --inputsrc <serial_number> --realsense_enabled</code> |
| USB camera        | <code>sudo ./docker-run.sh --workload opencv-ovms --platform core&#124;xeon&#124;dgpu.x --inputsrc /dev/video0</code>                         |
| Video file      | <code>sudo ./docker-run.sh --workload opencv-ovms --platform core&#124;xeon&#124;dgpu.x --inputsrc file:my_video_file.mp4</code>              |

**_Note:_**  For simulated camera as input source, please [run camera simulator first](../run_camera_simulator.md).

**_Note:_**  The value of x in `dgpu.x` can be 0, 1, 2, and so on depending on the number of discrete GPUs in the system.
    
**_Note:_**  Follow these [steps](../query_usb_camera.md) to see the output formats supported by your USB camera.

### Optional Parameters

The following are the optional parameters that you can provide as input to `docker-run.sh`. Note that these parameters would affect the performance of the pipeline. 
    
- `--classification_disabled`: Disables the classification process of image extraction. By default, the classification is enabled. 

- `--ocr_disabled`: Disables optical character recognition (OCR). By default, OCR is enabled. 

- `--ocr`: Provides the OCR frame internal value, such as `--ocr 5 GPU`. The default recognition interval value is 5. Note device equal to CPU is not supported when executing with a discrete GPU.

- `--barcode_disabled`: Disables barcode detection. By default, barcode detection is enabled.
    
- `--realsense_enabled`: Uses the Intel® RealSense™ Camera and provides the 12-digit serial number of the camera as an input to the `docker-run.sh` script.

- `--barcode`: Provides barcode detection frame internal value such as `--barcode 5`, default recognition interval value is 5.

- `--color-width`, `color-height`, and `color-framerate`: Allows you to customize the settings of the color frame output from the Intel® RealSense™ Cameras. This parameter will overwrite the default value of RealSense gstreamer. Use `rs-enumerate-devices` to look up the camera's color capability.


### Supporting different programming languages for OVMS grpc client
We are supporting multiple programming languages for OVMS grpc client. Currently we are supporting grpc-python and grpc-go. The scripts to start pipelines above would start grpc-python as default. [See more on supporting different language](./supportingDifferentLanguage.md)

### Supporting different models for OVMS grpc python client
With OVMS grpc-python client, you can configure to use different model to run the inferencing pipeline. The scripts to start pipelines above would start grpc-python using `instance_segmentation_omz_1040` model as default. [See more on supporting different model](./supportingDifferentModel.md)

### Status of Running a Pipeline
    
When you run the pipeline, the containers will run.
    
Check if the pipeline run is successful: 

```bash
docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}' -a
```

**Success**

Here is an example output:
| IMAGE                                              | STATUS                       | NAMES         |
| -------------------------------------------------- | ---------------------------- |---------------|
| ovms-client:latest                                 | Exited (0) 29 seconds ago    | ovms-client0  |
| openvino/model_server-gpu:latest                   | Up 59 seconds                | model-server0 |


Check inference results and use case performance
```bash
ls -l results
```
The **results** directory would contain pipeline0.log and r0.jsonl type of log files, each type of log files will postfix with a number, that is the corresponding pipeline index number.

!!! Failure
    If you do not see above Docker container(s), review the console output for errors. Sometimes dependencies fail to resolve and must be run again. Address obvious issues and try again repeating the above steps. Here are couple debugging tips:

    1. check the docker logs using following command

    ```bash
    docker logs <containerName>
    ```
    2. check ovms log in automated-self-checkout/results/r0.jsonl

---

## Sample output
### results/r0.jsonl sample
The output in results/r0.jsonl file lists average processing time in milliseconds and average number of frames per second. It's not really human readable, meant to be parsed by scripts. Below is a snap shot of the output:
```text
Processing time: 53.17 ms; fps: 18.81
Processing time: 47.98 ms; fps: 20.84
Processing time: 48.35 ms; fps: 20.68
Processing time: 46.88 ms; fps: 21.33
Processing time: 47.56 ms; fps: 21.03
Processing time: 49.66 ms; fps: 20.14
Processing time: 52.49 ms; fps: 19.05
Processing time: 52.27 ms; fps: 19.13
Processing time: 50.86 ms; fps: 19.66
Processing time: 58.19 ms; fps: 17.18
Processing time: 58.28 ms; fps: 17.16
Processing time: 52.17 ms; fps: 19.17
Processing time: 50.89 ms; fps: 19.65
Processing time: 49.58 ms; fps: 20.17
Processing time: 51.14 ms; fps: 19.55
```

### results/pipeline0.log sample:
The output in results/pipeline0.log lists average number of frames per second. Below is a snap shot of the output:
```text
18.81
20.84
20.68
21.33
21.03
20.14
19.05
19.13
19.66
17.18
17.16
19.17
19.65
20.17
19.55
```

**_Note:_**  The automated-self-checkout/results/ directory is volume mounted to the pipeline container.

---
## Coming up next

Run a benchmark for a use case/pipeline