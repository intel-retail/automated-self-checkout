# Run Pipeline

## Prerequisites 
Before running, [set up the pipeline](./pipelinesetup.md).

---
## Overview 
When the pipeline is run, the `docker-run.sh` script starts the service and performs inferencing on the selected input media. The output of running the pipeline provides the inference results for each frame based on the media source such as text, barcode, and so on, as well as the frames per second (FPS). Pipeline run provides many options in media type, system process platform type, and additional optional parameters. These options give you the opportunity to compare what system process platform is better for your need.

## Start Pipeline

You can run the pipeline script, `docker-run.sh`, with the following input parameters:

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

| Input Source Type | Scripts                                                                                                |
| ----------------- | -------------------------------------------------------------------------------------------------------|
| Simulated camera  | <code>sudo ./docker-run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc rtsp://127.0.0.1:8554/camera_0</code>|
| RealSense camera  | <code>sudo ./docker-run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc <serial_number> --realsense_enabled</code>        |
| USB camera        | <code>sudo ./docker-run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc /dev/video0</code>                         |
| Video file      | <code>sudo ./docker-run.sh --platform core&#124;xeon&#124;dgpu.x --inputsrc file:my_video_file.mp4</code>             |
    

**_Note:_**  The value of x in `dgpu.x` can be 0, 1, 2, and so on depending on the number of discrete GPUs in the system.
    
### Optional Parameters

The following are the optional parameters that you can provide as input to `docker-run.sh`. Note that these parameters would affect the performance of the pipeline. 
    
- `--classification_disabled`: Disables the classification process of image extraction when applying model. By default, the classification is enabled. 

- `--ocr_disabled`: Disables optical character recognition (OCR) when applying model. By default, OCR is enabled. 

- `--ocr`: Provides the OCR frame internal value, such as `--ocr 5 GPU`. The default recognition interval value is 5. Note device equal to CPU is not supported when executing with a discrete GPU.

- `--barcode_disabled`: Disables barcode detection when applying model. By default, barcode detection is enabled.
    
- `--realsense_enabled`: Uses the Intel® RealSense™ Camera and provides the 12-digit serial number of the camera as an input to the `docker-run.sh` script.

- `--barcode`: Provides barcode detection frame internal value such as `--barcode 5`, default recognition interval value is 5.

- `--color-width`: Realsense camera color related property, to apply realsense camera color width, which will overwrite the default value of realsense gstreamer; if it's not provided, it will use the default value from realsense gstreamer; make sure to look up to your realsense camera's color capability using `rs-enumerate-devices`

- `--color-height`: Realsense camera color related property, to apply realsense camera color height, which will overwrite the default value of realsense gstreamer; if it's not provided, it will use the default value from realsense gstreamer; make sure to look up to your realsense camera's color capability using `rs-enumerate-devices`

- `--color-framerate`: Realsense camera color related property, to apply realsense camera color framerate, which will overwrite the default value of realsense gstreamer; if it's not provided, it will use the default value from realsense gstreamer; make sure to look up to your realsense camera's color capability using `rs-enumerate-devices`

Here is an example to run a RealSense pipeline with optional parameters:
```bash
sudo ./docker-run.sh --platform core --inputsrc <serial_number> --realsense_enabled --color-width 1920 --color-height 1080 --color-framerate 15 --ocr 5 CPU
```

### Status of Running a Pipeline
    
When you run the pipeline, the containers will run.
    
Check if the pipeine run is successful: 

```bash
docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}'
```

**Success**

Your output for Core is as follows:
| IMAGE                                              | STATUS                   | NAMES                 |
| -------------------------------------------------- | ------------------------ |-----------------------|
| sco-soc:2.0                                        | Up 9 seconds             | vision-self-checkout0 |

Your output for DGPU is as follows:
| IMAGE                                              | STATUS                   | NAMES                 |
| -------------------------------------------------- | ------------------------ |-----------------------|
| sco-dgpu:2.0                                       | Up 9 seconds             | vision-self-checkout0 |


If the run is successful, the **results** directory will contain the log files. Check the inference results and use case performance:
    
```bash
ls -l results
```

The **results** directory contains the **pipeline*.log** files for each pipeline/workload that is running and is the pipeline/workload current FPS (throughput) results. This directory also contains **r*.jsonl** for each of pipeline/workload that is running and is the pipeline/workload inference results.
    
Here are the sample outputs:
    
**results/r0.jsonl sample**:

The **results/r0.jsonl** file lists all the metadata detected in each frame such as text, barcode, and so on. The output is not in human readable format and are meant to be parsed by scripts. 

```json
{"objects":[{"classification_layer_name:efficientnet-b0/model/head/dense/BiasAdd/Add":{"confidence":10.4609375,"label":"n07892512 red wine","label_id":966,"model":{"name":"efficientnet-b0"}},"detection":{"bounding_box":{"x_max":0.7873224129905809,"x_min":0.6722826382852345,"y_max":0.7966044796082201,"y_min":0.14121232192034938},"confidence":0.8745479583740234,"label":"bottle","label_id":39},"h":472,"id":1,"region_id":425,"roi_type":"bottle","w":147,"x":861,"y":102},{"classification_layer_name:efficientnet-b0/model/head/dense/BiasAdd/Add":{"confidence":10.6796875,"label":"n03983396 pop bottle, soda bottle","label_id":737,"model":{"name":"efficientnet-b0"}},"detection":{"bounding_box":{"x_max":0.3218779225315407,"x_min":0.2033093693251269,"y_max":0.7871318890289452,"y_min":0.14268490515908283},"confidence":0.8566966652870178,"label":"bottle","label_id":39},"h":464,"id":2,"region_id":426,"roi_type":"bottle","w":152,"x":260,"y":103},{"classification_layer_name:efficientnet-b0/model/head/dense/BiasAdd/Add":{"confidence":12.7109375,"label":"n03983396 pop bottle, soda bottle","label_id":737,"model":{"name":"efficientnet-b0"}},"detection":{"bounding_box":{"x_max":0.5719389945131272,"x_min":0.42213395664250974,"y_max":0.9703782149659794,"y_min":0.12828537611924062},"confidence":0.8436160683631897,"label":"bottle","label_id":39},"h":606,"id":3,"region_id":427,"roi_type":"bottle","w":192,"x":540,"y":92},{"detection":{"bounding_box":{"x_max":0.7873224129905809,"x_min":0.6722826382852345,"y_max":0.7966044796082201,"y_min":0.14121232192034938},"confidence":0.8745479583740234,"label":"bottle","label_id":39},"h":472,"region_id":425,"roi_type":"bottle","w":147,"x":861,"y":102},{"detection":{"bounding_box":{"x_max":0.3218779225315407,"x_min":0.2033093693251269,"y_max":0.7871318890289452,"y_min":0.14268490515908283},"confidence":0.8566966652870178,"label":"bottle","label_id":39},"h":464,"region_id":426,"roi_type":"bottle","w":152,"x":260,"y":103},{"detection":{"bounding_box":{"x_max":0.5719389945131272,"x_min":0.42213395664250974,"y_max":0.9703782149659794,"y_min":0.12828537611924062},"confidence":0.8436160683631897,"label":"bottle","label_id":39},"h":606,"region_id":427,"roi_type":"bottle","w":192,"x":540,"y":92}],"resolution":{"height":720,"width":1280},"timestamp":133305309}
...
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

The **results** directory is volume mounted to the pipeline container. The log files within the **results** increase as the pipeline continues to run. You can [stop the pipeline](/pipelinerun.md#stop-pipeline-run) and the containers that are running.

**Failure**
Review the console output for errors if you do not see all the Docker* containers. Sometimes dependencies fail to resolve. Address obvious issues and [rerun the pipeline](/pipelinerun.md#Rstart-pipeline).
    
---
    
### Stop Pipeline

Run the following command to stop the pipeline and the containers that are running:
    
```
./stop_all_docker_containers.sh
```

---
## Run Camera Simulator
    
Do the following to run the cameral simulator:

1. Download the video files to the **sample-media** directory: 
    ```bash
    cd benchmark-scripts; 
    sudo ./download_sample_videos.sh; 
    cd ..;
    ``` 
   You can also download a sample video and RTSP stream by specifying a resolution and framerate: 
   ```bash
   cd benchmark-scripts; sudo ./download_sample_videos.sh 1920 1080 15; cd ..;
   ```
   The example downloads a sample video for 1080p@15fps. Note that only AVC encoded files are supported.

2. After the video files are downloaded to the **sample-media** folder, start the camera simulator:
    ```bash
    ./camera-simulator/camera-simulator.sh
    ``` 

Wait for few seconds, and then check if the camera-simulator containers are running:
```bash
docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}'
```

**Success**
    Your output is as follows:

| IMAGE                                              | STATUS                   | NAMES             |
| -------------------------------------------------- | ------------------------ |-------------------|
| openvino/ubuntu20_data_runtime:2021.4.2            | Up 11 seconds            | simulator_docker  |
| aler9/rtsp-simple-server                           | Up 13 seconds            | camera-simulator  |

**_Note:_** There could be multiple containers with the image "openvino/ubuntu20_data_runtime:2021.4.2", depending on number of sample-media video files you have.

**Failure**
 
Review the console output for errors if you do not see all the Docker* containers. Sometimes dependencies fail to resolve. Address obvious issues and [rerun the camera simulator](#run-camera-simulator).




## Sample output

---
## Next

Run a [benchmark for a use case/pipeline](./pipelinebenchmarking.md)
