# Run Pipeline

## Prerequisites 
Before running, [set up the pipeline](./pipelinesetup.md).

---
## Overview 
When the pipeline is run, the `docker-run.sh` script starts the service and performs inferencing on the selected input media. The output of running the pipeline provides the inference results for each frame based on the media source such as text, barcode, and so on, as well as the frames per second (FPS). Pipeline run provides many options in media type, system process platform type, and additional optional parameters. These options give you the opportunity to compare what system process platform is better for your need.

## Start Pipeline

You can run the pipeline script, `docker-run.sh` with `--workload opencv-ovms` option, and the following additional input parameters:

- Media type 
    - Camera Simulator using RTSF
    - Intel® RealSense™ Camera
    - USB Camera
    - Video File
- Platform
    - core
    - dgpu.0
    - dgpu.1
    - xeon
 - [Optional parameters](#optional-parameters)
 
 The following table lists the commands for various input combinations. Run the command based on your requirement.

You have to get your choices for #1, #2, #3 above to start the pipeline run, see [details](#run-pipeline-with-different-input-sourceinputsrc-types) section below.

### Check successful pipeline run
Once pipeline run has started, you will expect containers to be running, see [check for pipeline run success](#status-of-running-a-pipeline); For a successful run, see [sample output log file](#sample-output).

### Stop pipeline run
You can call `make clean-all` to stop the pipeline and all running containers, hence the results directory log files will stop growing. Below is the table of make commands you can call to clean things up per your needs:

| Clean Containers Options                          | Command                           |
| --------------------------------------------------| ----------------------------------|
| clean ovms-client container                       | <pre>make clean-ovms-client</pre> |
| clean model-server container                      | <pre>make clean-model-server</pre>|
| clean both ovms-client and model-server containers| <pre>make clean-ovms</pre>        |

---

## Run pipeline with different input source(inputsrc) types
Use docker-run.sh to run the pipeline, here is the table of basic scripts for each combination:
| Input source Type |Command                                                                                                                                        |          
|-------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| simulated camera  | <code>sudo ./docker-run.sh --workload opencv-ovms --platform core&#124;xeon&#124;dgpu.x --inputsrc rtsp://127.0.0.1:8554/camera_0</code>      |
| realsense camera  | <code>sudo ./docker-run.sh --workload opencv-ovms --platform core&#124;xeon&#124;dgpu.x --inputsrc <serial_number> --realsense_enabled</code> |
| USB camera        | <code>sudo ./docker-run.sh --workload opencv-ovms --platform core&#124;xeon&#124;dgpu.x --inputsrc /dev/video0</code>                         |
| a video file      | <code>sudo ./docker-run.sh --workload opencv-ovms --platform core&#124;xeon&#124;dgpu.x --inputsrc file:my_video_file.mp4</code>              |

**_Note:_**  The value of x in `dgpu.x` can be 0, 1, 2, and so on depending on the number of discrete GPUs in the system.
    
**_Note:_**  Follow these [steps](/How_to_query_usb_camera.md) to see the output formats supported by your USB camera.
    
### Optional Parameters

The following are the optional parameters that you can provide as input to `docker-run.sh`. Note that these parameters would affect the performance of the pipeline. 
    
- `--classification_disabled`: Disables the classification process of image extraction. By default, the classification is enabled. 

- `--ocr_disabled`: Disables optical character recognition (OCR). By default, OCR is enabled. 

- `--ocr`: Provides the OCR frame internal value, such as `--ocr 5 GPU`. The default recognition interval value is 5. Note device equal to CPU is not supported when executing with a discrete GPU.

- `--barcode_disabled`: Disables barcode detection. By default, barcode detection is enabled.
    
- `--realsense_enabled`: Uses the Intel® RealSense™ Camera and provides the 12-digit serial number of the camera as an input to the `docker-run.sh` script.

- `--barcode`: Provides barcode detection frame internal value such as `--barcode 5`, default recognition interval value is 5.

- `--color-width`, `color-height`, and `color-framerate`: Allows you to customize the settings of the color frame output from the Intel® RealSense™ Cameras. This parameter will overwrite the default value of RealSense gstreamer. Use `rs-enumerate-devices` to look up the camera's color capability.


### Status of Running a Pipeline
    
When you run the pipeline, the containers will run.
    
Check if the pipeine run is successful: 

```bash
docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}' -a
```

**Success**

Your output is as follows:
| IMAGE                                              | STATUS                       | NAMES        |
| -------------------------------------------------- | ---------------------------- |--------------|
| ovms-client:latest                                 | Exited (0) 29 seconds ago    | ovms-client0 |
| openvino/model_server-gpu:latest                   | Up 59 seconds                | model-server |


Check inference results and use case performance
```bash
ls -l results
```

The **results** directory should contain maskrcnn.log


!!! Failure
    If you do not see above Docker container(s), review the console output for errors. Sometimes dependencies fail to resolve and must be run again. Address obvious issues and try again repeating the above steps. Here are couple debugging tips:

    1.check the docker logs using following command

    ```bash
    docker logs <containerId>
    ```
    2. check ovms log in automated-self-checkout/results/maskrcnn.log

---
## Sample output

### results/maskrcnn.log sample:

The output in results/maskrcnn.log file lists all the meta data for what was detected in each frame such as text, barcode, etc. It's not really human readable, meant to be parsed by scripts. Below is a snap shot of the output:

```text
Start processing:
	Model name: instance-segmentation-security-1040
Iteration 0; Processing time: 72.94 ms; speed 13.71 fps

processing time for all iterations
average time: 72.00 ms; average speed: 13.89 fps
median time: 72.00 ms; median speed: 13.89 fps
max time: 72.00 ms; min speed: 13.89 fps
min time: 72.00 ms; max speed: 13.89 fps
time percentile 90: 72.00 ms; speed percentile 90: 13.89 fps
time percentile 50: 72.00 ms; speed percentile 50: 13.89 fps
time standard deviation: 0.00
time variance: 0.00
```

**_Note:_**  The automated-self-checkout/results/ directory is volume mounted to the pipeline container.

---
## Coming up next

Run a benchmark for a use case/pipeline