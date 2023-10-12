# Computer Vision Pipeline Benchmarking

You can benchmark pipelines with a collection of scripts to get the pipeline performance metrics such as video processing in frame-per-second (FPS), memory usage, power consumption, and so on.

## Prerequisites
Before benchmarking, make sure you [set up the pipeline](./pipelinesetup.md).

## Steps to Benchmark Computer Vision Pipelines

### Step 1: Build the benchmark Docker* images
Benchmark scripts are containerized inside Docker. The following table lists the commands for various platforms. Choose and run the command corresponding to your hardware configuration.

| Platform                                   | Docker Build Command      | Check Success                                |
| ------------------------------------------ | ------------------------- |----------------------------------------------|
| Intel® integrated and Arc™ GPUs | <pre>cd benchmark-scripts<br>make build-benchmark<br>make build-igt</pre> | Docker images command to show both <b>`benchmark:dev`</b> and <b>`benchmark:igt`</b> images |
| Intel® Flex GPUs   | <pre>cd benchmark-scripts<br>make build-benchmark<br>make build-xpu</pre> | Docker images command to show both <b>`benchmark:dev`</b> and <b>`benchmark:xpu`</b> images |

!!! Warning
    Build command may take a while, depending on your internet connection and machine specifications.

### Step 2: Run the benchmark
The `benchmark.sh` shell script is in the **base** > **benchmark_scripts** directory. Before executing this script, change the current directory to **benchmark_scripts**.

The `benchmark.sh` will either benchmark a [specific number of pipelines](./pipelinebenchmarking.md#benchmark-specified-number-of-ipelines) or [benchmark stream density](./pipelinebenchmarking.md#benchmark-stream-density) based on the desired FPS.  
  
Before running pipeline benchmark for a specific use case, determine the following:

- [Input source type](./pipelinebenchmarking.md#input-source-type)
- [Platform](./pipelinebenchmarking.md#platform)
- [Workload](./pipelinebenchmarking.md#workload)
- [Profile for OVMS workload](./pipelinebenchmarking.md#benchmark-specified-profile)

#### Input Source Type

The benchmark script can take either of the following video input sources:

- **Real Time Streaming Protocol (RTSP)**
     ```bash
     --inputsrc rtsp://127.0.0.1:8554/camera_0
     ```
   !!! Note
        Using RTSP source with `benchmark.sh` will automatically run the camera simulator. The camera simulator will start an RTSP stream for each video file in the **sample-media** folder.

- **USB Camera**
    ```bash
    --inputsrc /dev/video<N>, where N is 0 or an integer
    ```
- **Intel® RealSense™ Camera**
    ```bash
    --inputsrc <RealSense camera serial number>
    ```
    To know the serial number of the Intel® RealSense™ Camera, refer to [Get Serial Number of Intel® RealSense™ Camera](./camera_serial_number.md).

- **Video File**
    ```bash
    --inputsrc file:my_video_file.mp4
    ```
    
    !!! Note
        Video files must be in the **sample-media** folder, so that the Docker container can access the files. You can provide your own video files or download a sample video file using the script [download_sample_videos.sh](https://github.com/intel-retail/automated-self-checkout/blob/main/benchmark-scripts/download_sample_videos.sh).

#### Platform

- **Intel® Core™ Processor**
    - `--platform core.x` if GPUs are available, then replace this parameter with targeted GPUs such as core (for all GPUs), core.0, core.1, and so on
    - `--platform core` will evenly distribute and utilize all available core GPUs

- **Intel® Xeon® Scalable Processor**
    - `--platform xeon` will use the Xeon CPU for the pipelines

- **DGPU (Intel® Data Center GPU Flex 140,  Intel® Data Center GPU Flex 170, and Intel® Arc™ Setup)**

    - `--platform dgpu.x` replace this parameter with targeted GPUs such as dgpu (for all GPUs), dgpu.0, dgpu.1, and so on
    - `--platform dgpu` will evenly distribute and utilize all available dgpus

---
### Benchmark Specified Number of Pipelines

The primary purpose of benchmarking with a specified number of pipelines is to discover the performance and system requirements for a given use case.

!!! Example
    
    Here is an example of running benchmarking pipelines with specified number of pipelines:
    ```bash
    sudo ./benchmark.sh --pipelines <number of pipelines> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects>
    ```

    where, the configurable input parameters include: 

    - `--performance_mode` configures the scaling governor of the system. Supported modes are performance and powersave (default).
    - `--logdir` configures the benchmarking output directory
    - `--duration` configures the duration, in number of seconds, the benchmarking will run
    - `--init_duration` configures the duration, in number of seconds, to wait for system initialization before the benchmarking metrics or data collection begins

!!! Example
    You can run multiple pipeline benchmarking with different configurations before consolidating all pipeline output results.
    
    To get the consolidated pipeline results, run the following `make` command:
    ```bash
    make consolidate ROOT_DIRECTORY=<output dir>
    ```
    This command will consolidate the performance metrics that exist in the specified `ROOT_DIRECTORY`. 
    
    Here is an example of consolidated output: 
    
    !!! Success
        Output of ``Consolidate_multiple_run_of_metrics.py``
    
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
### Benchmark Stream Density

Benchmarking a pipeline can also discover the maximum number of workloads or streams that can be ran in parallel for a given target FPS. This information is useful to determine the hardware required to achieve the desired performance for input sources.

To run the stream density functionality:
```bash
sudo ./benchmark.sh --stream_density <target FPS> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects>
```
!!! Note
    It is recommended to set ``--stream_density`` to a value lesser than your target FPS to account for real world variances in hardware readings.

!!! Note
    Because stream density requires a continuous video stream it is recommended to use an RTSP stream, USB camera, or RealSense camera. If these options are not available you can use the [camera simulator](#appendix-benchmark-helper-scripts) to continuously loop through a video file as an RTSP stream.

---

#### Workload
We are currently supporting 2 types of workloads:
    1. dlstreamer
    2. ovms

These are the input value for `--workload` parameter for benchmark.sh script. The default value for `--workload` parameter is `dlstreamer` in case it is not provided when running benchmark.sh script.

#### Benchmark Specified Profile for OVMS
For running ovms workload, we are supporting different programming languages and different models. You may specify [language choice](./OVMS/supportingDifferentLanguage.md) and [model input](./OVMS/supportingDifferentModel.md). Then you may **prefix** benchmark script run command with specific profile.

An example of stream density benchmark script in golang:
```bash
PIPELINE_PROFILE="grpc_go" sudo -E ./benchmark.sh --stream_density 14.9 --logdir mytest/data --duration 60 --init_duration 20 --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --workload ovms
```

An example of stream density benchmark script in python:
```bash
PIPELINE_PROFILE="grpc_python" sudo -E ./benchmark.sh --stream_density 14.9 --logdir mytest/data --duration 60 --init_duration 60 --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --workload ovms
```
If prefix is not provided, then the default value is "grpc_python".

## Additional Benchmark Examples

**Run decode+pre-processing+object detection (Yolov5s 416x416) only pipeline**:

```bash
sudo ./benchmark.sh --pipelines <number of pipelines> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <4k rtsp stream with 5 objects> --ocr_disabled --barcode_disabled --classification_disabled
```

```bash
sudo ./benchmark.sh --stream_density <target FPS> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects> --ocr_disabled --barcode_disabled --classification_disabled
```

**Run decode+pre-processing+object detection (Yolov5s 416x416) + efficientnet-b0 (224x224) only pipeline**:

```bash
sudo ./benchmark.sh --pipelines <number of pipelines> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <4k rtsp stream with 5 objects> --ocr_disabled --barcode_disabled
```

```bash
sudo ./benchmark.sh --stream_density <target FPS> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects> --ocr_disabled --barcode_disabled
```

**Run  decode+pre-processing+object detection (Yolov5s 416x416) + efficientnet-b0 (224x224) + optical character recognition + barcode detection and decoding**

```bash
sudo ./benchmark.sh --pipelines <number of pipelines> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <4k rtsp stream with 5 objects> --ocr 5 GPU
```

```bash
sudo ./benchmark.sh --stream_density <target FPS> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects> --ocr 5 GPU
```

**Run Flex140 optimized decode+pre-processing+object detection (Yolov5s 416x416) + efficientnet-b0 (224x224) + optical character recognition + barcode detection and decoding:**
```bash
sudo ./benchmark.sh --pipelines 2 --logdir <output dir>/data1 --init_duration 30 --duration 120 --platform dgpu.0 --inputsrc <4k rtsp stream with 5 objects> --ocr 5 GPU

sudo ./benchmark.sh --pipelines 2 --logdir <output dir>/data1 --init_duration 30 --duration 120 --platform dgpu.1 --inputsrc <4k rtsp stream with 5 objects> --ocr 5 GPU
```

```bash
sudo ./benchmark.sh --stream_density <target FPS> --logdir <output dir>/data --init_duration 30 --duration 120 --platform dgpu --inputsrc <ex:4k rtsp stream with 10 objects> --ocr 5 GPU
```

---
## Appendix: Benchmark Helper Scripts

- `camera-simulator.sh`: This script starts the camera simulator. Create two folders named **camera-simulator** and **sample-media**. Place `camera-simulator.sh` in the **camera-simulator** folder. Manually copy the video files to the **sample-media** folder or run the [`download_sample_videos.sh`](https://github.com/intel-retail/automated-self-checkout/blob/main/benchmark-scripts/download_sample_videos.sh) script to download sample videos. The `camera-simulator.sh` script will start a simulator for each *.mp4* video that it finds in the **sample-media** folder and will enumerate them as camera_0, camera_1, and so on. Make sure that the path to the `camera-simulator.sh` script is mentioned correctly in the `camera-simulator.sh` script.  

- `stop_server.sh`: This script stops and removes all Docker containers closing the pipelines.
