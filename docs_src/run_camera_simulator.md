If you do not have a camera device plugged into the system, run the camera simulator to view the pipeline analytic results based on a sample video file to mimic real time camera video. You can also use the camera simulator to infinitely loop through a video file for consistent benchmarking. For example, if you want to validate whether the performance is the same for 6 hours, 12 hours, and 24 hours, looping the same video should produce the same results regardless of the duration.

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
| openvino/ubuntu20_data_runtime:2021.4.2            | Up 11 seconds            | camera-simulator0 |
| aler9/rtsp-simple-server                           | Up 13 seconds            | camera-simulator  |

**_Note:_** There could be multiple containers with the image "openvino/ubuntu20_data_runtime:2021.4.2", depending on number of sample-media video files you have.

**Failure**

Review the console output for errors if you do not see all the Docker* containers. Sometimes dependencies fail to resolve. Address obvious issues and try again.
