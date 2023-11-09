# Query USB Camera

1. Make sure a USB camera is plugged into the system

2. Install the necessary libraries

    ```bash
    sudo apt update
    sudo apt install v4l-utils -y
    ```

3. List available video cameras 

    ```bash
    ls -l /dev/vid*
    ```

    !!! Note
        To get information about the development video ids, check the [![List dev video ids](./images/list_dev_videos.png)](./images/list_dev_videos.png)

4. Execute a video, from the available list, for more information

    ```bash
    v4l2-ctl --list-formats-ext -d /dev/video0
    ```

    !!! Note
        Here is information on how to [![Execute a dev video](./images/execute_a_dev_video.png)](./images/execute_a_dev_video.png).

!!! Example
    Here is an example to run the pipeline with a USB camera on video0 for the core system:
    ```bash
    sudo ./run.sh --platform core --inputsrc /dev/video0
    ```
