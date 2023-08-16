# Run Pipeline

## Prerequisites 
Before running, [set up the pipeline](./pipelinesetup.md).

---
## Overview 
When the pipeline is run, the `docker-run.sh` script starts the service and performs inferencing on the selected input media. The output of running the pipeline provides the inference results for each frame based on the media source such as text, barcode, and so on, as well as the frames per second (FPS). Pipeline run provides many options in media type, system process platform type, and additional optional parameters. These options give you the opportunity to compare what system process platform is better for your need.

## Start Pipeline

You can run the pipeline script, `docker-run.sh`, with the following input parameters:

1. Media type
    - Camera Simulator using RTSF
    - Intel® RealSense™ Camera
    - USB Camera
    - Video File
2. Platform
    - core
    - dgpu.0
    - dgpu.1
    - xeon
3. [Optional parameters](#optional-parameters)
 
Run the command based on specific requirements. Select choices for #1, #2, #3 above to start the pipeline run, see [details](#run-pipeline-with-different-input-sourceinputsrc-types) section below.

### Check successful pipeline run
Once pipeline run has started, you will expect containers to be running, see [check for pipeline run success](#check-for-pipeline-run-success); For a successful run, you should expect results/ directory filled with log files and you can watch these log files grow, see [sample output log files](#sample-output).

### Stop pipeline run
You can call `make clean` to stop the pipeline container, hence the results directory log files will stop growing. Below is the table of make commands you can call to clean things up per your needs:

| Clean Containers Options                                         | Command                         |
| -----------------------------------------------------------------| --------------------------------|
| clean simulator containers                                       | <pre>make clean-simulator</pre> |
| clean sco-* containers                                           | <pre>make clean</pre>           |
| clean simulator and self-checkout containers and results/ folder | <pre>make clean-all</pre>       |

---
## Run pipeline with different input source(inputsrc) types
Use docker-run.sh to run the pipeline, here is the table of basic scripts for each combination:

| Input source Type | scripts                                                                                                |
| ----------------- | -------------------------------------------------------------------------------------------------------|
| Simulated camera  | <code>sudo ./docker-run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc rtsp://127.0.0.1:8554/camera_0</code>|
| RealSense camera  | <code>sudo ./docker-run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc <serial_number> --realsense_enabled</code>        |
| USB camera        | <code>sudo ./docker-run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc /dev/video0</code>                         |
| Video file      | <code>sudo ./docker-run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc file:my_video_file.mp4</code>             |

**_Note:_**  For simulated camera as input source, [run camera simulator first](./run_camera_simulator.md).

**_Note:_**  The value of x in `dgpu.x` can be 0, 1, 2, and so on depending on the number of discrete GPUs in the system.
    
**_Note:_**  Follow these [steps](./query_usb_camera.md) to see the output formats supported by your USB camera.
    
### Optional Parameters

The following are the optional parameters that you can provide as input to `docker-run.sh`. Note that these parameters would affect the performance of the pipeline. 
    
- `--classification_disabled`: Disables the classification process of image extraction. By default, the classification is enabled. 

- `--ocr_disabled`: Disables optical character recognition (OCR). By default, OCR is enabled. 

- `--ocr`: Provides the OCR frame internal value, such as `--ocr 5 GPU`. The default recognition interval value is 5. Note device equal to CPU is not supported when executing with a discrete GPU.

- `--barcode_disabled`: Disables barcode detection. By default, barcode detection is enabled.
    
- `--realsense_enabled`: Uses the Intel® RealSense™ Camera and provides the 12-digit serial number of the camera as an input to the `docker-run.sh` script.

- `--barcode`: Provides barcode detection frame internal value such as `--barcode 5`, default recognition interval value is 5.

- `--color-width`, `color-height`, and `color-framerate`: Allows you to customize the settings of the color frame output from the Intel® RealSense™ Cameras. This parameter will overwrite the default value of RealSense gstreamer. Use `rs-enumerate-devices` to look up the camera's color capability.

Here is an example to run a RealSense pipeline with optional parameters:
```bash
sudo ./docker-run.sh --platform core --inputsrc <serial_number> --realsense_enabled --color-width 1920 --color-height 1080 --color-framerate 15 --ocr 5 CPU
```

### Environment variables
When running docker-run.sh script, we support environment variables as input for container. [Here is a list of environment variables and how to apply](./environment_variables.md)

### Status of Running a Pipeline
    
When you run the pipeline, the containers will run.
    
Check if the pipeine run is successful: 

```bash
docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}'
```

**Success**

Your output for Core is as follows:
| IMAGE                                              | STATUS                   | NAMES                    |
| -------------------------------------------------- | ------------------------ |--------------------------|
| sco-soc:2.0                                        | Up 9 seconds             | automated-self-checkout0 |

Your output for DGPU is as follows:
| IMAGE                                              | STATUS                   | NAMES                    |
| -------------------------------------------------- | ------------------------ |--------------------------|
| sco-dgpu:2.0                                       | Up 9 seconds             | automated-self-checkout0 |


If the run is successful, the **results** directory will contain the log files. Check the inference results and use case performance:
    
```bash
ls -l results
```

The **results** directory contains three types of log files:

    - **pipeline#.log** files for each pipeline/workload that is running and is the pipeline/workload current FPS (throughput) results.
    - **r#.jsonl** for each of pipeline/workload that is running and is the pipeline/workload inference results.
    - **gst-launch_device_#.log** for gst-launch console output helping for debug; the `device` in file name can be core|dgpu|xeon.

The **#** suffixed to each log file name corresponds to each pipeline run index number.

## Sample output

Here are the sample outputs:
    
**results/r0.jsonl sample**:

The **results/r0.jsonl** file lists all the metadata detected in each frame such as text, barcode, and so on. The output is not in human readable format and are meant to be parsed by scripts. 

```json
{
    "objects": [
        {
            "classification_layer_name:efficientnet-b0/model/head/dense/BiasAdd/Add": {
                "confidence": 10.4609375,
                "label": "n07892512 red wine",
                "label_id": 966,
                "model": {
                    "name": "efficientnet-b0"
                }
            },
            "detection": {
                "bounding_box": {
                    "x_max": 0.7873224129905809,
                    "x_min": 0.6722826382852345,
                    "y_max": 0.7966044796082201,
                    "y_min": 0.14121232192034938
                },
                "confidence": 0.8745479583740234,
                "label": "bottle",
                "label_id": 39
            },
            "h": 472,
            "id": 1,
            "region_id": 425,
            "roi_type": "bottle",
            "w": 147,
            "x": 861,
            "y": 102
        },
        {
            "detection": {
                "bounding_box": {
                    "x_max": 0.7873224129905809,
                    "x_min": 0.6722826382852345,
                    "y_max": 0.7966044796082201,
                    "y_min": 0.14121232192034938
                },
                "confidence": 0.8745479583740234,
                "label": "bottle",
                "label_id": 39
            },
            "h": 472,
            "region_id": 425,
            "roi_type": "bottle",
            "w": 147,
            "x": 861,
            "y": 102
        }
    ],
    "resolution": {
        "height": 720,
        "width": 1280
    },
    "timestamp": 133305309
}
```

**results/pipeline0.log sample***:

The **results/pipeline0.log** file lists FPS during pipeline run. 

```text
27.34
27.34
27.60
27.60
28.30
28.30
28.61
28.61
28.48
28.48
...
```

The **results** directory is volume mounted to the pipeline container. The log files within the **results** increase as the pipeline continues to run. You can [stop the pipeline](./pipelinerun.md#stop-pipeline-run) and the containers that are running.

**Failure**
    
Review the console output for errors if you do not see all the Docker* containers. Sometimes dependencies fail to resolve. Address obvious issues and [rerun the pipeline](./pipelinerun.md#start-pipeline).
    
---
    
### Stop Pipeline

Run the following command to stop the pipeline and the containers that are running:
    
```
./stop_all_docker_containers.sh
```

---
## Next

Run a [benchmark for a use case/pipeline](./pipelinebenchmarking.md)
