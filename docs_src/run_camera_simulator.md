# Camera Simulator

## Overview

If you do not have a camera device plugged into the system, run the camera simulator to view the pipeline analytic results based on a sample video file to mimic real time camera video. You can also use the camera simulator to infinitely loop through a video file for consistent benchmarking. For example, if you want to validate whether the performance is the same for 6 hours, 12 hours, and 24 hours, looping the same video should produce the same results regardless of the duration.

## Run the Camera Simulator

Follow the steps below to run the camera simulator:

1. Download the video files to the **sample-media** directory:
    ```bash
    cd benchmark-scripts;
    ./download_sample_videos.sh;
    cd ..;
    ```
   
    !!! Example - Specify Resolution and Framerate
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
