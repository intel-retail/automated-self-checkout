# Set up Pipeline

1. Clone the repository

    ```bash
    git clone  https://github.com/intel-retail/automated-self-checkout.git && cd ./automated-self-checkout
    ```

2. Build the profile launcher binary executable

    ```bash
    make build-profile-launcher
    ```

    Each profile is an unique pipeline use case.  We provide some profile examples, and the configuration examples of profiles [are located here](https://github.com/intel-retail/automated-self-checkout/tree/main/configs/opencv-ovms/cmd_client/res).  [Go here](profileLauncherConfigs.md) to find out the detail descriptions for the configuration of profile used by profile launcher.

3. Build the benchmark Docker images

    ```bash
    cd benchmark-scripts
    make build-all

    cd ..
    ```

    !!! Note
        A successfully built benchmark Docker images should contain the following Docker images from `docker images` command:

        - benchmark:dev
        - benchmark:xpu
        - benchmark:igt

    !!! Note
        After successfully built benchmark Docker images, please remember to change the directory back to the project base directory from the current benchmark-scripts directory (i.e. `cd ..`) for the following steps.        

4. Download the models manually (Optional)

    !!! Note
        The model downloader script is automatically called as part of run.sh.
    
    ```bash
    ./download_models/getModels.sh
    ```
    
    !!! Warning
        Depending on your internet connection, this might take some time.


5. (Optional) Download the video file manually. This video is used as the input source to give to the pipeline.

    !!! Note
        The sample image downloader script is automatically called as part of run.sh. 

    ```bash
    ./configs/opencv-ovms/scripts/image_download.sh
    ```

    !!! Warning
        Depending on your internet connection, this might take some time.


6. (optional) Download the bit model manually 

    a. Here is the command to build the container for bit model downloading:
    
    ```bash
    docker build -f Dockerfile.bitModel -t bit_model_downloader:dev .
    ```

    b. Here is the script to run the container that downloads the bit models:
    
    ```bash
    docker run -it bit_model_downloader:dev
    ```

7. Build the reference design images. This table shows the commands for the OpenVINO (OVMS) model Server and profile-launcher build command:

    | Target                            | Docker Build Command               | Check Success                                                          |
    | ----------------------------------| -----------------------------------|------------------------------------------------------------------------|
    | OVMS Server                       | <pre>make build-ovms-server</pre>  | `docker images` command output contains Docker image openvino/model_server:2023.1-gpu</b>  |
    | OVMS Profile Launcher             | <pre>make build-profile-launcher</pre>  | `ls -al ./profile-launcher` command to show the binary executable                |

    !!! Note
        Build command may take a while, depending on your internet connection and machine specifications.
    
    !!! Note
        If the build command succeeds, you will see all the built Docker images files as indicated in the **Check Success** column. If the build fails, check the console output for errors.
    
    !!! Proxy
        If docker build system requires a proxy network, just set your proxy env standard way on your terminal as below and make build:
    
        ```bash
        export HTTP_PROXY="http://your-proxy-url.com:port"
        export HTTPS_PROXY="https://your-proxy-url.com:port"
        make build-ovms-server
        make build-profile-launcher
        ```
