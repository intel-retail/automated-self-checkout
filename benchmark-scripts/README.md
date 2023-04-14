# Benchmarking

## Installation
Install the benchmark utilities required  

chmod +x *.sh

sudo ./utility_install.sh  


## Benchmark Data Collection (NEW)
This section is to replace the below Benchmark Data Collection after validation.

**benchmark.sh**

Before starting this script ensure the ../samples-media folder has the needed video to benchmark against. 

This script will start benchmarking a specific number of pipelines or can start stream density benchmarking based on the parameters. 

Inputs: The parameters are nearly the same as docker-run and docker-run-dev. There x new parameters to add first:

--pipelines NUMBER_OF_PIPELINES_TO_START or  --stream_density TARGET_FPS
--logdir PATH_TO_LOG_DIR/data 
--duration NUMBER_OF_SECONDS_TO_BENCHMARK
--init_duration NUMBER_OF_SECONDS_TO_WAIT_BEFORE_STARTING_DATA_COLLECTION 

For the remaining parameters e.g. --platform, --inputsrc,etc see docker-run.sh.

Example for running product detection use case for 30 seconds after waiting 60 seconds for initialization.
sudo ./benchmark.sh --pipelines 2 --logdir yolov5s_serpcanyon_grocery-shelf/data --duration 30 --init_duration 60 --platform dgpu.1 --inputsrc rtsp://127.0.0.1:8554/camera_0 --classification_disabled --ocr_disabled --barcode_disabled

Additional sample command lines:  

1. sudo ./benchmark.sh --pipelines 4 --logdir yolov5s_serpcanyon_grocery-shelf/data --duration 120 --init_duration 30 --platform dgpu --inputsrc rtsp://127.0.0.1:8554/camera_0
2. sudo ./benchmark.sh --pipelines 4 --logdir yolov5s_serpcanyon_grocery-shelf/data --duration 120 --init_duration 30 --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
3. sudo ./benchmark.sh --pipelines 4 --logdir yolov5s_serpcanyon_grocery-shelf/data --duration 120 --init_duration 30 --platform xeon --inputsrc rtsp://127.0.0.1:8554/camera_0
4. sudo ./benchmark.sh --stream_density 15 --logdir yolov5s_serpcanyon_grocery-shelf/data --duration 120 --init_duration 30 --platform xeon --inputsrc rtsp://127.0.0.1:8554/camera_0

**consolidate_multiple_run_of_metrics.py**

Use this script once all testing is complete. The consolidate_multiple_run_of_metrics.py will  consolidate the benchmarks into one .csv summary file.  

Inputs to the script are:  

1. --root_directory: the top level directory where the results are stored  
2. --output: the location to put the output file  

Sample command line:  
sudo python3 ./consolidate_multiple_run_of_metrics.py --root_directory yolov5s_6330N/ --output yolov5s_6330N/consolidated.csv  


## Benchmark Data Collection (REMOVE ME)

**collect_video_metrics.sh**

Use this script to start benchmarking a specific workload. Note that this script depends on camera_simulator.sh, docker-run.sh and stop_pipelines.sh  

Before starting this script ensure the ../samples-media folder has the needed video to benchmark against. 


Inputs to the collect_video_metrics.sh script are:  

1. CAMERA_ID: the video stream to be run for the workload. Needs to be the full path ie: rtsp://127.0.0.1:8554/camera_0  
2. PIPELINE_NUMBER: the number of pipelines to start  
3. LOG_DIRECTORY: the location to store all the log files. The consolidation script will look for directories within the top level directory and process the results in each one so the user will want to keep in mind this structure when creating the log directory. For example, for multiple videos with different number of objects, a log_directory would look like: yolov5s_6330N/object1_mixed. Whatever is meaningful for the test run.  
4. DURATION: the amount of time to run the data collection  
5. COMPLETE_INIT_DURATION: the amount of time to allow the system to settle prior to starting the data collection.  
6. DEVICE: Use soc if testing for CPU/iGPU or dgpu if testing for Flex or Arc GPUs
7. SYSTEM: core or xeon

Sample command lines:  
1. sudo ./collect_video_metrics.sh rtsp://127.0.0.1:8554/camera_0 4 yolov5s_6330N/object5_mixed 120 30  dgpu xeon
2. sudo ./collect_video_metrics.sh rtsp://127.0.0.1:8554/camera_0 4 yolov5s_6330N/object5_mixed 120 30  soc core
3. sudo ./collect_video_metrics.sh rtsp://127.0.0.1:8554/camera_0 4 yolov5s_6330N/object5_mixed 120 30  soc xeon

**consolidate_multiple_run_of_metrics.py**

Use this script once all testing is complete. The consolidate_multiple_run_of_metrics.py will  consolidate the benchmarks into one .csv summary file.  

Inputs to the script are:  

1. --root_directory: the top level directory where the results are stored  
2. --output: the location to put the output file  

Sample command line:  
sudo python3 ./consolidate_multiple_run_of_metrics.py --root_directory yolov5s_6330N/ --output yolov5s_6330N/consolidated.csv  


**stop_server.sh**

Stops the docker images closing the pipelines  

**stream_density.sh**

Use this script to test maximum streams that can be run on your system. output will be the maximum pipelines ran with the last fps recorded.

Inputs to the script are:

1. CAMERA_ID: the video stream to be run for the workload. Needs to be the full path ie: rtsp://127.0.0.1:8554/camera_0  
2. PLATFORM: core, xeon, or dgpu.x
    - dgpu.x should be replaced with targetted GPUs such as dgpu (for all GPUs), dgpu.0, dgpu.1, etc
3. TARGET_FPS: the minimum target frame per second for pipelines to reach

Sample command lines:  
1. sudo ./stream_density.sh rtsp://127.0.0.1:8554/camera_0 core 15

## Benchmark Helper Scripts

**camera-simulator.sh**

Starts the camera simulator. To use, place the script in a folder named camera-simulator. At the same directory level as the camera-simulator folder, create a folder called sample-media. The camera-simulator.sh script will start a simulator for each .mp4 video that it finds in the sample-media folder and will enumerate them as camera_0, camera_1 etc.  Be sure the path to camera-simulator.sh script is correct in the start_emulated_camera_pipelines.sh script.  




