# Pipeline Benchmarking

Pipeline benchmarking is done through a collection of scripts to obtain the pipeline performance metrics like video processing in frame-per-second (FPS),
how much memory is used, how much power is consumed, ... and so on.

## Prerequisites: 
Pipeline setup needs to be completed first, pipeline setup documentation can be found [HERE](./pipelinesetup.md).

## Step 1: Build Benchmark Docker Images
Benchmark scripts are containerized inside Docker, depending on platforms/hardware you have, refer to the following table to choose one to build:

| Platform                                   | Docker Build Command      | Check Success                                |
| ------------------------------------------ | ------------------------- |----------------------------------------------|
| Intel platforms with Intel integrated GPUs | <pre>cd benchmark-scripts<br>make build-benchmark<br>make build-igt</pre> | docker images command to show both <b>benchmark:dev</b> and <b>benchmark:igt</b> images |
| Intel platforms with Intel discrete GPUs   | <pre>cd benchmark-scripts<br>make build-benchmark<br>make build-xpu</pre> | docker images command to show both <b>benchmark:dev</b> and <b>benchmark:xpu</b> images |

!!! note
    Build command may take a while to run depending on your internet connection and machine specifications.

## Step 2: Run Benchmark
The `benchmark.sh` shell script is located under `benchmark_scripts` directory under the base directory.  Before executing this script,
change the current directory to directory `benchmark_scripts`.

This script will start benchmarking a specific number of pipelines or can start stream density benchmarking based on the desired FPS to reach.  
Before running pipeline benchmarking for a given use case, determine the appropriate inputs, from the list below:

### Determine the input source type

The benchmark script can take one of these video input sources as described below:

### Real Time Streaming Protocol (RTSP)

    --inputsrc rtsp://127.0.0.1:8554/camera_0

!!! note
    Using RTSP source with the benchmark.sh will automatically run the camera simulator. The camera simulator will start an RTSP stream for each video file found in the `sample-media` folder.

### USB Camera

    --inputsrc /dev/video<N>, where N is 0 or an integer

### RealSense Camera

    --inputsrc <RealSense camera serial number>

#### Obtaining RealSense camera serial number

[Follow this link to get serial number](./camera_serial_number.md)

### Video File

    --inputsrc file:my_video_file.mp4

!!! note
    Video files must be in `sample-media` folder to be accessible from the Docker container. You can provide your own video files or download a sample video file using the script [download_sample_videos.sh](https://github.com/intel-retail/automated-self-checkout/blob/main/benchmark-scripts/download_sample_videos.sh).

---
### Determine the platform

#### Intel® Core

- `--platform core.x` if GPUs are available, then replace this parameter with targeted GPUs such as core (for all GPUs), core.0, core.1, etc

- `--platform core` will evenly distribute and utilize all available core GPUs

#### Intel® Xeon SP

- `--platform xeon` will use the xeon CPU for the pipelines

#### DGPU (Intel® Data Center GPU Flex 140 & 170 and Intel® Arc™ Setup)

- `--platform dgpu.x` should be replaced with targeted GPUs such as dgpu (for all GPUs), dgpu.0, dgpu.1, etc

- `--platform dgpu` will evenly distribute and utilize all available dgpus

---

### Specified number of pipelines

The main purpose of running the benchmarking with a specified number of pipelines is to discover the performance and system requirements for a given use case.

**Example:** to run benchmarking pipelines with specified number of pipelines:
```bash
sudo ./benchmark.sh --pipelines <number of pipelines> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects>
```

where some of configurable input parameters are:
- --logdir configures the benchmarking output directory
- --duration configures how long the benchmarking will run in number of seconds
- --init_duration configures how long initially, in number of seconds, to wait for system initialization before the benchmarking metrics or data collection begins

and multiple pipeline benchmarking runs with different configurations can be completed before consolidating all pipeline output results.

To get consolidated pipeline results, run the following `make` command:
```bash
make consolidate ROOT_DIRECTORY=<output dir>
```
and this will give all the performance metrics among different workload cases given the same root directory specified by `ROOT_DIRECTORY` as shown above.

One of the consolidation example outputs is shown below:

### Consolidate_multiple_run_of_metrics.py output example
```excel
,Metric,data
0,Total Text count,0
1,Total Barcode count,2
2,Camera_1 FPS,15.0
3,Camera_0 FPS,15.0
4,CPU Utilization %,16.548
5,Memory Utilization %,21.162
6,Disk Read MB/s,0.0
7,Disk Write MB/s,0.025
8,S0 Memory Bandwidth Usage MB/s,1872.632
9,S0 Power Draw W,27.502
10,GPU_0 VDBOX0 Utilization %,0.0
11,GPU_0 GPU Utilization %,17.282
```

---
### Stream density

Another thing pipeline benchmarking can do is to discover the maximum number of workloads/streams that can be ran in parallel for a given target FPS.  This can be useful to determine the hardware requirements in order to achieve the desired performance for input sources.

To run stream density functionality:
```bash
sudo ./benchmark.sh --stream_density <target FPS> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects>
```

!!!note
    It is recommended to set the --stream_density slightly under your target FPS to account for real world variances in HW readings.

---
## Additional Benchmark Examples

### Run decode+pre-processing+object detection (Yolov5s 416x416) only pipeline:

```bash
sudo ./benchmark.sh --pipelines <number of pipelines> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <4k rtsp stream with 5 objects> --ocr_disabled --barcode_disabled --classification_disabled
```

```bash
sudo ./benchmark.sh --stream_density <target FPS> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects> --ocr_disabled --barcode_disabled --classification_disabled
```

### Run decode+pre-processing+object detection (Yolov5s 416x416) + efficientnet-b0 (224x224) only pipeline:

```bash
sudo ./benchmark.sh --pipelines <number of pipelines> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <4k rtsp stream with 5 objects> --ocr_disabled --barcode_disabled
```

```bash
sudo ./benchmark.sh --stream_density <target FPS> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects> --ocr_disabled --barcode_disabled
```

### Run  decode+pre-processing+object detection (Yolov5s 416x416) + efficientnet-b0 (224x224) + optical character recognition + barcode detection and decoding :

```bash
sudo ./benchmark.sh --pipelines <number of pipelines> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <4k rtsp stream with 5 objects> --ocr 5 GPU
```

```bash
sudo ./benchmark.sh --stream_density <target FPS> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects> --ocr 5 GPU
```

### Run  Flex140 optimized decode+pre-processing+object detection (Yolov5s 416x416) + efficientnet-b0 (224x224) + optical character recognition + barcode detection and decoding :
```bash
sudo ./benchmark.sh --pipelines 2 --logdir <output dir>/data1 --init_duration 30 --duration 120 --platform dgpu.0 --inputsrc <4k rtsp stream with 5 objects> --ocr 5 GPU

sudo ./benchmark.sh --pipelines 2 --logdir <output dir>/data1 --init_duration 30 --duration 120 --platform dgpu.1 --inputsrc <4k rtsp stream with 5 objects> --ocr 5 GPU
```

```bash
sudo ./benchmark.sh --stream_density <target FPS> --logdir <output dir>/data --init_duration 30 --duration 120 --platform dgpu --inputsrc <ex:4k rtsp stream with 10 objects> --ocr 5 GPU
```

---
## Appendix: Benchmark Helper Scripts

- **camera-simulator.sh**

Starts the camera simulator. To use, place the script in a folder named camera-simulator. At the same directory level as the camera-simulator folder, create a folder called sample-media. The camera-simulator.sh script will start a simulator for each .mp4 video that it finds in the sample-media folder and will enumerate them as camera_0, camera_1 etc.  Be sure the path to camera-simulator.sh script is correct in the camera-simulator.sh script.  

- **stop_server.sh**

Stops the docker images closing the pipelines  