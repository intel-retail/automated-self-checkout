# Query USB Camera

### Step 1: Set up camera hardware
Make sure a USB camera is plugged into the system

### Step 2: Install library

`sudo apt update; apt install v4l-utils -y`

### Step 3: List available video cameras 

`ls -l /dev/vid*`

[![List dev video ids](./images/list_dev_videos.png)](./images/list_dev_videos.png)

### Step 4: Execute a video, from the available list, for more information

`v4l2-ctl --list-formats-ext -d /dev/video0`

[![Execute a dev video](./images/execute_a_dev_video.png)](./images/execute_a_dev_video.png)

Here is an example to run the pipeline with a USB camera on video0 for the core system:
```
sudo ./run.sh --platform core --inputsrc /dev/video0
```
