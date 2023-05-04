# Pipeline Benchmarking

## Prerequisites: 
Pipeline setup needs to be done first, pipeline setup documentation be found [HERE](./pipelinesetup.md)

## Step 1: Run Benchmark
The benchmark.sh shell script is located under `benchmark_scripts` directory under the base directory.  Before executing this script,
change the current directory to directory `benchmark_scripts`.

### Determine the input source type

### RTSP

    --inputsrc rtsp://127.0.0.1:8554/camera_0

- **__NOTE:__** using RTSP source with the benchmark.sh will automatically run the camera simulator. The camera simulator will start an RTSP stream for each video file found in the sample-media folder.

### USB Camera

    --inputsrc /dev/videoN, where N is 0 or integer number

### RealSense Camera

    --inputsrc <camera serial number> 

#### Obtaining RealSense camera serial number

[How_to_get_serial_number](./camera_serial_number.md)

### File

    --inputsrc file:my_video_file.mp4

- **__NOTE:__** files must be in sample-media folder to access from the Docker container. You can provide your own video files or download a video using [download_sample_videos.sh](https://github.com/intel-retail/vision-self-checkout/benchmark-scripts/download_sample_videos.sh).


---

### Determine the platform

#### Intel® Core

- `--platform core.x` should be replaced with targeted GPUs such as core (for all GPUs), core.0, core.1, etc

- `--platform core` will evenly distribute and utilize all available core GPUs

#### Intel® Xeon SP

- `--platform xeon` will use the xeon CPU for the pipelines

#### DGPU (Intel® Data Center GPU Flex 140 & 170 and Intel® Arc™ Setup)

- `--platform dgpu.x` should be replaced with targeted GPUs such as dgpu (for all GPUs), dgpu.0, dgpu.1, etc

- `--platform dgpu` will evenly distribute and utilize all available dgpus

---

### Specified number of pipelines ( Discover the the performance and system requirements for a given use case )

Run benchmarking pipelines:
```bash
sudo ./benchmark.sh --pipelines <number of pipelines> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects>
```
Note: you need to run `./dokcer-build-igt.sh` under /vision-self-checkout folder before you run above benchmarking pipeline for Core

Get consolidated pipeline results:
```bash
sudo python3 consolidate_multiple_run_of_metrics.py --root_directory <output dir>/ --output <output dir>/consolidated.csv
```

### Consolidate_multiple_run_of_metrics.py output example
```
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

### Stream density (Discover the maximum number of workloads/streams that can be ran in parallel for a given stream_density target FPS)

Run Stream Density:
```bash
sudo ./benchmark.sh --stream_density <target FPS> --logdir <output dir>/data --init_duration 30 --duration 120 --platform <core|xeon|dgpu.x> --inputsrc <ex:4k rtsp stream with 10 objects>
```


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
