# Quick Start Guide to Run Pipeline

## Prerequisites
Before running, [set up the pipeline](./pipelinesetup.md).

## Running OVMS with the camera simulator

### Start the Camera Simulator

1. Download the video files to the **sample-media** directory:
    ```bash
    cd benchmark-scripts;
    ./download_sample_videos.sh;
    cd ..;
    ```

    !!! Example "Example - Specify Resolution and Framerate"
        This example downloads a sample video for 1080p@15fps.
        ```bash
        cd benchmark-scripts;
        ./download_sample_videos.sh 1920 1080 15;
        cd ..;
        ```

    !!! Note
        Only AVC encoded files are supported.

2. After the video files are downloaded to the **sample-media** folder, start the camera simulator:
    ```bash
    make run-camera-simulator
    ```

3. Wait for few seconds, and then check if the camera-simulator containers are running:
    ```bash
    docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}'
    ```

    !!! Success
        Your output is as follows:
    
        | IMAGE                                              | STATUS                   | NAMES             |
        | -------------------------------------------------- | ------------------------ |-------------------|
        | openvino/ubuntu20_data_runtime:2021.4.2            | Up 11 seconds            | camera-simulator0 |
        | aler9/rtsp-simple-server                           | Up 13 seconds            | camera-simulator  |
    
    
        !!! Note
            There could be multiple containers with the image "openvino/ubuntu20_data_runtime:2021.4.2", depending on the number of sample-media video files provided.
    
    !!! Failure
        If all the Docker* containers are not visible, then review the console output for errors. Sometimes dependencies fail to resolve. Address obvious issues and retry.

### Run Instance Segmentation

There are several pipeline profiles to chose from. Use the `make list-profiles` to see the different pipeline options. In this example, the `instance_segmentation` pipeline profile will be used. 

1. Use the following command to run instance segmentation using OVMS on core.

    ```bash
    PIPELINE_PROFILE="instance_segmentation" RENDER_MODE=1 sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
    ```

2. Check the status of the pipeline.
   
    ```bash
    docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}' -a
    ```
    !!! Success
        Here is a sample output:

        | IMAGE                                              | STATUS                       | NAMES         |
        | -------------------------------------------------- | ---------------------------- |---------------|
        | openvino/model_server-gpu:latest                   | Up 59 seconds                | ovms-server0 |

    !!! Failure
   
        If you do not see above Docker container(s), review the console output for errors. Sometimes dependencies fail to resolve and must be run again. Address obvious issues and try again repeating the above steps. Here are couple debugging tips:
   
        1. check the docker logs using following command to see if there is an issue with the container
   
            ```bash
            docker logs <containerName>
            ```
        2. check ovms log in automated-self-checkout/results/r0.jsonl

3. Check the output in the `results` directory.

    !!! Example "Example - results/r0.jsonl sample"
        The output in results/r0.jsonl file lists average processing time in milliseconds and average number of frames per second. This file is intended for scripts to parse.
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

    !!! Example "Example - results/pipeline0.log sample"   
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
    
    !!! Note
        The automated-self-checkout/results/ directory is volume mounted to the pipeline container.

## Stop running the pipelines

1. To stop the instance segmentation container and clean up, run 
    ```bash
    make clean-all
    ```