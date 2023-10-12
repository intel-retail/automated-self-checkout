# Set up Pipeline

### Step 1: Clone the repository

```bash
git clone  https://github.com/intel-retail/automated-self-checkout.git && cd ./automated-self-checkout
```

### Step 2: Install Golang 1.20

In order to build the profile-launcher binary executable, you need to have Golang version 1.20 installed first.

Here is [the link to download](https://go.dev/dl/) Golang.

Follow the [installation instruction](https://go.dev/doc/install#Go_installation) with the same downloaded file name above for version 1.20.

### Step 3: Build the benchmark Docker images

For use cases that support benchmarking, build the benchmark Docker images:

```bash
cd benchmark-scripts
make build-all
```

### Step 4: Download the models manually (Optional)

When `run.sh` the Model downloader script is automatically called. the model downloader script is automatically called as part of run-ovms.sh (part of run.sh). You can also download the models manually using the model downloader script:

```bash
sh ./download_models/getModels.sh --workload ovms
```

!!! Note
    Depending on your internet connection, this might take less than a minute.


### Step 5: Download image file Manually (Optional)

The sample image downloader script is automatically called as part of run-ovms.sh. You can also download the sample image manually using script below:

```bash
sh ./configs/opencv-ovms/scripts/image_download.sh 
```

!!! Note
    Depending on your internet connection, this might take less than a minute.


### Step 6: Download bit model Manually (optional)

Here is the script to build container for bit model downloading:

```bash
docker build -f Dockerfile.bitModel -t bit_model_downloader:dev .
```

Here is the script to run container and downloads the bit models:

```bash
docker run -it bit_model_downloader:dev
```

### Step 7: Build the reference design images

You must build the provided component services and create local docker images. Below is the table for the OVMS Server and Client build command:

| Target                            | Docker Build Command               | Check Success                                                          |
| ----------------------------------| -----------------------------------|------------------------------------------------------------------------|
| OVMS Server                       | <pre>make build-ovms-server</pre>  | docker images command to show <b>openvino/model_server-gpu:latest</b>  |
|                                   |                                    | docker images command to show <b>openvino/model_server:latest-gpu</b>  |
|                                   |                                    | docker images command to show <b>openvino/model_server:latest</b>      |
|                                   |                                    | docker images command to show <b>openvino/model_server-pkg:latest</b>  |
|                                   |                                    | docker images command to show <b>openvino/model_server-build:latest</b>|
| OVMS Profile Launcher             | <pre>make build-profile-launcher</pre>  | <b>ls -al ./profile-launcher</b> command to show the binary executable                |

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

