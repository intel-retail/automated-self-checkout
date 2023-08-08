Before running the below (e.g. starting the camera-simulator.sh) ensure you have downloaded video file(s) to the `sample-media` directory. Execute the commands 
```bash
cd benchmark-scripts; sudo ./download_sample_videos.sh; cd ..;
``` 
These commands are provided as an option to download a sample video(s) and RTSP stream with the camera-simulator.  You can also specify the desired resolution and framerate e.g.
```bash
cd benchmark-scripts; sudo ./download_sample_videos.sh 1920 1080 15; cd ..;
```
for 1080p@15fps. Note that only AVC encoded files are supported.

Once video files are copied/downloaded to the sample-media folder, start the camera simulator from automated-self-checkout/ directory with:
```bash
make run-camera-simulator
``` 

!!!Note Please wait for few seconds, then use below command to check if camera-simulator containers are running.
```bash
docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}'
```

!!! success
    Your output is as follows:

| IMAGE                                              | STATUS                   | NAMES             |
| -------------------------------------------------- | ------------------------ |-------------------|
| openvino/ubuntu20_data_runtime:2021.4.2            | Up 11 seconds            | camera-simulator0 |
| aler9/rtsp-simple-server                           | Up 13 seconds            | camera-simulator  |

!!!Note there could be multiple containers with IMAGE "openvino/ubuntu20_data_runtime:2021.4.2", depending on number of sample-media video file you have.

!!! failure
    If you do not see all of the above docker containers, look through the console output for errors. Sometimes dependencies fail to resolve and must be run again. Address obvious issues. To try again, repeat [Run camera simulator](#run-camera-simulator).
