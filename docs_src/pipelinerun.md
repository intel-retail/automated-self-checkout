# Pipeline Run

## Prerequisites: 
Pipeline setup needs to be done first, pipeline setup documentation be found [HERE](./pipelinesetup.md)

## Run camera simulator
Before running the below (e.g. starting the camera-simulator.sh) ensure you have downloaded video file(s) to the `sample-media` directory. Execute the commands 
```
cd benchmark-scripts; sudo ./download_sample_videos.sh; cd ..;
``` 
These commands are provided as an option to download a sample video(s) and RTSP stream with the camera-simulator.  You can also specify the desired resolution and framerate needed e.g. 
```
cd benchmark-scripts; sudo ./download_sample_videos.sh 1920 1080 15; cd ..;
```
for 1080p@15fps. Note that only AVC encoded files are supported.

Once video files are copied/downloaded to the sample-media folder start the camera simulator with:
```
./camera-simulator/camera-simulator.sh
``` 

!!! Please wait for few seconds, then to use below command to check if camera-simulator containers are running.
```
docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}'
```

!!! success
    Your output is as follows:

    | IMAGE                                              | STATUS                   | NAMES             |
    | -------------------------------------------------- | ------------------------ |-------------------|
    | openvino/ubuntu20_data_runtime:2021.4.2            | Up 11 seconds            | simulator_docker  |
    | openvino/ubuntu20_data_runtime:2021.4.2            | Up 11 seconds            | simulator_docker2 |
    | aler9/rtsp-simple-server                           | Up 13 seconds            | camera-simulator  |

Note: there could be multiple containers with IMAGE "openvino/ubuntu20_data_runtime:2021.4.2", depending on number of sample-media video file you have.

!!! failure
    If you do not see all of the above docker containers, look through the consol output for errors. Sometimes dependencies fail to resolve and must be run again. Address obvious issues. To try again, repeat step 3.


## Run pipeline with different input source(inputsrc) types
Use docker-run.sh to run the pipeline

### Option 1 to run object detection, object classification, OCR, and barcode recognition with simulated camera:

#### For Core systems
```
sudo ./docker-run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
```

#### For Xeon systems
```
sudo ./docker-run.sh --platform xeon --inputsrc rtsp://127.0.0.1:8554/camera_0
```

#### For Discrete GPU systems
```
sudo ./docker-run.sh --platform dgpu.x --inputsrc rtsp://127.0.0.1:8554/camera_0 --ocr 5 GPU
```  
Note: for `dgpu.x`, the x can be 0, 1, 2 depends on how many discrete gpu it has in the system


### Option 2 to run object detection, object classification, OCR, and barcode recognition with USB Camera:

#### For Core systems
```
sudo ./docker-run.sh --platform core --inputsrc /dev/video0
```
Query USB camera: [How_to_query_usb_camera](./query_usb_camera.md)

### Option 3 to run with RealSense Camera(serial number input):

#### For Core systems
```
sudo ./docker-run.sh --platform core --inputsrc <serial_number> --realsense_enabled

```
Obtaining RealSense camera serial number: [How_to_get_serial_number](./camera_serial_number.md)

### Option 4 to run with video file input:

#### For Core systems
```
sudo ./docker-run.sh --platform core --inputsrc file:my_video_file.mp4
```

#### For Xeon systems
```
sudo ./docker-run.sh --platform xeon --inputsrc file:my_video_file.mp4
```

#### For Discrete GPU systems
```
sudo ./docker-run.sh --platform dgpu.x --inputsrc file:my_video_file.mp4 --ocr 5 GPU
```
Note: for `dgpu.x`, the x can be 0, 1, 2 depends on how many discrete gpu it has in the system


## Check for pipeline run success 

Make sure the command was successful. To do so, run:

```
docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}'
```

!!! Successful Results
    Your output for Core is as follows:

    | IMAGE                                              | STATUS                   | NAMES                 |
    | -------------------------------------------------- | ------------------------ |-----------------------|
    | sco-soc:2.0                                        | Up 9 seconds             | vision-self-checkout0 |

    Your output for DGPU is as follows:
    | IMAGE                                              | STATUS                   | NAMES                 |
    | -------------------------------------------------- | ------------------------ |-----------------------|
    | sco-dgpu:2.0                                       | Up 9 seconds             | vision-self-checkout0 |


Check inference results and use case performance
```
ls -l results
```

This directory contains pipeline*.log files for each pipeline/workload that is running and is the pipeline/workload current FPS (throughput) results.

This directory also contains r*.jsonl for each of pipeline/workload that is running and is the pipeline/workload inference results.


!!! Failure
    If you do not see above Docker container(s), review the console output for errors. Sometimes dependencies fail to resolve and must be run again. Address obvious issues and try again repeating the above steps.


## Optional parameters
The optional parameters you can apply to the docker-run.sh input, just note that they will affect the performance of pipeline run.

### `--classification_disabled`
To disable classification process of image extraction when applying model, default is NOT disabling classification if this is not provided as input to docker-run.sh

### `--ocr_disabled`
To disable Optical character recognition when applying model, default is NOT disabling ocr if this is not provided as input to docker-run.sh

### `--ocr`
To provide Optical character recogntion frame internal value such as `--ocr 5 GPU`, default recognition interval value is 5. Note device equal to CPU is not supported when executing with a discrete GPU.

### `--barcode_disabled`
To disable barcode detection when applying model, default is NOT disabling barcode detection if this is not provided as input to docker-run.sh

### `--realsense_enabled`
TO use realsense camera and to provide realsense camera 12 digit serial number as inputsrc to the docker-run.sh script

### `--barcode`
To provide barcode detection frame internal value such as `--barcode 5`, default recognition interval value is 5

### `--color-width`
Realsense camera color related property, to apply realsense camera color width, which will overwrite the default value of realsense gstreamer; if it's not provided, it will use the default value from realsense gstreamer; make sure to look up to your realsense camera's color capability using `rs-enumerate-devices`

### `--color-height`
Realsense camera color related property, to apply realsense camera color height, which will overwrite the default value of realsense gstreamer; if it's not provided, it will use the default value from realsense gstreamer; make sure to look up to your realsense camera's color capability using `rs-enumerate-devices`

### `--color-framerate`
Realsense camera color related property, to apply realsense camera color framerate, which will overwrite the default value of realsense gstreamer; if it's not provided, it will use the default value from realsense gstreamer; make sure to look up to your realsense camera's color capability using `rs-enumerate-devices`

## RealSense option pipeline run example:

`sudo ./docker-run.sh --platform core --inputsrc <serial_number> --realsense_enabled --color-width 1920 --color-height 1080 --color-framerate 15 --ocr 5 CPU`


## Sample output in results/r0.jsonl:

The output in results/r0.jsonl file is listing all the meta data for what was detected in each frame such as text, barcode, etc. It's not really human readable, meant to be parsed by scripts. See below as a snap shot of the output, this list will keep on growing as the pipeline is still running, you may call ./stop_all_docker_containers.sh to stop the pipeline and all running containers.

```
{"objects":[{"classification_layer_name:efficientnet-b0/model/head/dense/BiasAdd/Add":{"confidence":10.4609375,"label":"n07892512 red wine","label_id":966,"model":{"name":"efficientnet-b0"}},"detection":{"bounding_box":{"x_max":0.7873224129905809,"x_min":0.6722826382852345,"y_max":0.7966044796082201,"y_min":0.14121232192034938},"confidence":0.8745479583740234,"label":"bottle","label_id":39},"h":472,"id":1,"region_id":425,"roi_type":"bottle","w":147,"x":861,"y":102},{"classification_layer_name:efficientnet-b0/model/head/dense/BiasAdd/Add":{"confidence":10.6796875,"label":"n03983396 pop bottle, soda bottle","label_id":737,"model":{"name":"efficientnet-b0"}},"detection":{"bounding_box":{"x_max":0.3218779225315407,"x_min":0.2033093693251269,"y_max":0.7871318890289452,"y_min":0.14268490515908283},"confidence":0.8566966652870178,"label":"bottle","label_id":39},"h":464,"id":2,"region_id":426,"roi_type":"bottle","w":152,"x":260,"y":103},{"classification_layer_name:efficientnet-b0/model/head/dense/BiasAdd/Add":{"confidence":12.7109375,"label":"n03983396 pop bottle, soda bottle","label_id":737,"model":{"name":"efficientnet-b0"}},"detection":{"bounding_box":{"x_max":0.5719389945131272,"x_min":0.42213395664250974,"y_max":0.9703782149659794,"y_min":0.12828537611924062},"confidence":0.8436160683631897,"label":"bottle","label_id":39},"h":606,"id":3,"region_id":427,"roi_type":"bottle","w":192,"x":540,"y":92},{"detection":{"bounding_box":{"x_max":0.7873224129905809,"x_min":0.6722826382852345,"y_max":0.7966044796082201,"y_min":0.14121232192034938},"confidence":0.8745479583740234,"label":"bottle","label_id":39},"h":472,"region_id":425,"roi_type":"bottle","w":147,"x":861,"y":102},{"detection":{"bounding_box":{"x_max":0.3218779225315407,"x_min":0.2033093693251269,"y_max":0.7871318890289452,"y_min":0.14268490515908283},"confidence":0.8566966652870178,"label":"bottle","label_id":39},"h":464,"region_id":426,"roi_type":"bottle","w":152,"x":260,"y":103},{"detection":{"bounding_box":{"x_max":0.5719389945131272,"x_min":0.42213395664250974,"y_max":0.9703782149659794,"y_min":0.12828537611924062},"confidence":0.8436160683631897,"label":"bottle","label_id":39},"h":606,"region_id":427,"roi_type":"bottle","w":192,"x":540,"y":92}],"resolution":{"height":720,"width":1280},"timestamp":133305309}
...
```

## Sample output in results/pipeline0.log:

The output in results/pipeline0.log file is listing FPS (frames per second) during pipeline run. See below as a snap shot of the output, this list will keep on growing as the pipeline is still running, you may call ./stop_all_docker_containers.sh to stop the pipeline and all running containers.

```
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

This pipeline will keep on running and output in results directory pipeline0.log and r0.jsonl will keep on growing until you stop the containers.
you can call ./stop_all_docker_containers.sh to stop all running containers.

## Next

Run a [benchmark for a use case/pipeline](./pipelinebenchmarking.md)