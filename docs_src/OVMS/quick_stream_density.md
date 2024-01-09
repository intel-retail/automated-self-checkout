# Quick Start Guide to Run Pipeline Stream Density

In this section, we show the steps to run the stream density for a chosen pipeline profile.  By definition, the objective of the stream density is
to bench-mark the maximum number of multiple running pipelines at the same time while still maintaining the goal-setting target frames-per-second (FPS).

## Prerequisites

Before running, [set up the pipeline](./pipelinesetup.md) if not already done.

### Stop All Other Running Pipelines

To make sure we have a good stream density benchmarking, it is recommended to stop all other running pipelines before running the stream density.
To stop all running pipelines and clean up, run
    ```bash
    make clean-all
    ```

### Build Benchmark Docker Images

For running stream density, the benchmark scripts are utilized.  To set up the benchmarking, we need to build the benchmark Docker images first.

1. Build the benchmark Docker* images
    Benchmark scripts are containerized inside Docker. The easiest way to build all benchmark Docker images, run
        ```bash
        cd ./benchmark-scripts
        make
        ```
    
    It is also possible to choose which benchmark Docker images to build based on different platforms.

    The following table lists the commands for various platforms. Choose and run the command corresponding to your hardware configuration.

    | Platform                                   | Docker Build Command      | Check Success                                |
    | ------------------------------------------ | ------------------------- |----------------------------------------------|
    | Intel® integrated and Arc™ GPUs | <pre>cd benchmark-scripts<br>make build-benchmark<br>make build-igt</pre> | Docker images command to show both <b>`benchmark:dev`</b> and <b>`benchmark:igt`</b> images |
    | Intel® Flex GPUs   | <pre>cd benchmark-scripts<br>make build-benchmark<br>make build-xpu</pre> | Docker images command to show both <b>`benchmark:dev`</b> and <b>`benchmark:xpu`</b> images |
    
    !!! Warning
        Build command may take a while, depending on your internet connection and machine specifications.

### Start the Camera Simulator

We will use the camera simulator as the input source to show the stream density. Please refer to [the section of Start the Camera Simulator in Quick Start Guide to Run Pipeline](./quick_pipelinerun.md#start-the-camera-simulator) on how to start the camera simulator.

### Run Objection Detection Pipeline Stream Density

There are several pipeline profiles to choose from for running pipeline stream density. Use the `make list-profiles` to see the different pipeline options. In this example, the `object_detection` pipeline profile will be used for running stream density.

1. To run the stream density, the benchmark shell script, `benchmark.sh`, is used. The script is in the **&lt;project_base_dir&gt;**/**benchmark-scripts** directory.  Use the following command to run objection detection pipeline profile using OVMS on core.

    ```bash
    cd ./benchmark-scripts
    PIPELINE_PROFILE="object_detection" RENDER_MODE=0 sudo -E ./benchmark.sh --stream_density 15.0 --logdir object_detection/data --duration 120 --init_duration 40 --platform core --inputsrc rtsp://127.0.0.1:8554/camera_1
    ```

    !!! Note
        Description of some key benchmarking input parameters is given as below:

        | Parameter Name       | Example Value | Description                               |
        | ------------------------------------------ | ------------------------- |----------------------------------------------|
        | --stream_density | 15.0 | The value 15.0 after the --stream_density is the target FPS that we want to achieve for running maximum number of object detection pipelines while the averaged of all pipelines from the output FPS still maintaining that target FPS value. |
        | --logdir   | object_detection/data | the output directory of benchmarking resource details |
        | --duration   | 120 | the time duration, in number of seconds, the benchmarking will run |
        | --init_duration | 40 | the time duration, in number of seconds, to wait for system initialization before the benchmarking metrics or data collection begins |

    !!! Note
        For stream density run, it is recommended to turn off the display to conserve the system resources hence setting `RENDER_MODE=0`

    !!! Note
        This takes a while for the whole stream density benchmarking process depending on your system resources like CPU, memory, ... etc.

    !!! Note
        The benchmark.sh script automatically cleans all running Docker containers after it is done.


    One can also run the benchmarking on different devices like CPU or GPU if hardware supports.  This can be done through the environment variable `DEVICE`.  The following is an example to run the object_detection profile using GPU:

    ```bash
    PIPELINE_PROFILE="object_detection" RENDER_MODE=0 DEVICE="GPU.0" sudo -E ./benchmark.sh --stream_density 14.95 --logdir object_detection/data --duration 120 --init_duration 40 --platform dgpu.0 --inputsrc rtsp://127.0.0.1:8554/camera_1
    ```

    !!! Note
        The performance of running object detection benchmarking should be better while running on GPU using model precision FP32.  To change the model precision if supports, you can go to the folder `configs/opencv-ovms/models/2022` from the root of project folder and edit the `base_path` for that particular model in the `config_template.json` file.  For example, you can change the the base_path of `FP32` to `FP16` assuming the precision `FP16` of the model is available: 
        
        ```json
            ...
            "config": {
            "name": "ssd_mobilenet_v1_coco",
            "base_path": "/models/ssd_mobilenet_v1_coco/FP32",
            ...
            }

        ```


2. Check the output in the base `results` directory.

    After the stream density is done, the results of stream density can be seen on the base directory of the `results` directory:

    ```bash
    cat ../results/stream_density.log
    ```

    !!! Example "Example - results/stream_density.log sample"
        The output in results/stream_density.log file gives the detailed information of stream density results:
         ```text
            ......
            FPS for pipeline0: 15.1225
            FPS for pipeline1: 15.19
            FPS for pipeline2: 15.18
            Total FPS throughput: 45.4925
            Total FPS per stream: 15.1642
            Max stream density achieved for target FPS 15.0 is 3
            Finished stream density benchmarking
            stream_density done!
         ```
