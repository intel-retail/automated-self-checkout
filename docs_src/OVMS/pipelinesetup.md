# Set up Pipeline

### Step 1: Clone the repository

```
git clone  https://github.com/intel-retail/automated-self-checkout.git && cd ./automated-self-checkout
```

### Step 2: Build the benchmark images (coming up)

For use cases that support benchmarking, build the benchmark images:

```bash
cd benchmark-scripts
make build-all
```

### Step 3: Download the models manually (Optional)

When `docker-run.sh` the Model downloader script is automatically called. the model downloader script is automatically called as part of docker-run-opencv-ovms.sh (part of docker-run.sh). You can also download the models manually using the model downloader script:

```bash
sh ./download_models/getModels.sh --workload opencv-ovms
```

**_Note:_**  Depending on your internet connection, this might take less than a minute.


### Step 4: Download image file Manually (Optional)

The sample image downloader script is automatically called as part of docker-run-opencv-ovms.sh. You can also download the sample image manually using script below:

```bash
sh ./configs/opencv-ovms/scripts/image_download.sh 
```

**_Note:_** Depending on your internet connection, this might take less than a minute.


### Step 5: Download bit model Manually (optional)

Here is the script to build container for bit model downloading:

```bash
docker build -f Dockerfile.bitModel -t bit_model_downloader:dev
```

Here is the script to run container and downloads the bit models:

```bash
docker run -it bit_model_downloader:dev
```

### Step 6: Build the reference design Docker* images

You must build the provided component services and create local docker images. Below is the table for the OVMS Server and Client build command:

| Target                            | Docker Build Command               | Check Success                                                          |
| ----------------------------------| -----------------------------------|------------------------------------------------------------------------|
| OVMS Server                       | <pre>make build-ovms-server</pre>  | docker images command to show <b>openvino/model_server-gpu:latest</b>  |
|                                   |                                    | docker images command to show <b>openvino/model_server:latest-gpu</b>  |
|                                   |                                    | docker images command to show <b>openvino/model_server:latest</b>      |
|                                   |                                    | docker images command to show <b>openvino/model_server-pkg:latest</b>  |
|                                   |                                    | docker images command to show <b>openvino/model_server-build:latest</b>|
| OVMS Client                       | <pre>make build-ovms-client</pre>  | docker images command to show <b>ovms-client:latest</b>                |

**_Note:_** Build command may take a while, depending on your internet connection and machine specifications.

**_Note:_** If the build command succeeds, you will see all the built Docker images files as indicated in the **Check Success** column. If the build fails, check the console output for errors. The dependencies might have been unable to resolve. Address the issue and repeat [from step 3](/pipelinesetup.md#step-3).

**Build with proxy**: If the Docker build system requires a proxy network, provide the proxy URL after the first argument. Here is an example to build the reference design Docker image with the proxy information:

!!! build with proxy information:
    If docker build system requires a proxy network, just set your proxy env standard way on your terminal as below and make build:
```bash
export HTTP_PROXY="http://your-proxy-url.com:port"
export HTTPS_PROXY="https://your-proxy-url.com:port"
make build-ovms-server
make build-ovms-client
```



#### Next

Run a [use case/pipeline](./pipelinerun.md)
