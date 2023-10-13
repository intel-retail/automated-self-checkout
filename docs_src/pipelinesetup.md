# Set up Pipeline

### Step 1: Clone the repository

```bash
git clone  https://github.com/intel-retail/automated-self-checkout.git && cd ./automated-self-checkout
```

### Step 2: Build the benchmark containers

For use cases that support benchmarking, build the benchmark containers:

```bash
cd benchmark-scripts
make build-all
```

### Step 3: Download the models manually (Optional)

When `run.sh` the Model downloader script is automatically called. You can also download the models manually using the model downloader script:

```bash
sh modelDownload.sh
```

!!! Warning
    This step might take a while as the script will download several models for the first time.

!!! Note
    For the list of pre-trained models, refer to the [Model List](https://github.com/intel-retail/automated-self-checkout/blob/main/configs/dlstreamer/models/2022/models.list.yml).

### Step 4: Build the reference design Docker* images

You must build the provided component services and create local docker images. The following table lists the build command for various platforms. Choose and run the command corresponding to your platforms or hardware.

| Platform                                       | Docker Build Command                       | Check Success                                                |
| ---------------------------------------------- | ------------------------------------------ |--------------------------------------------------------------|
| Intel platforms using DLStreamer               | <pre>make build-dlstreamer</pre>           | docker images command to show <b>sdlstreamer:2.0</b>         |
| Intel platforms using DLStreamer and Realsense | <pre>make build-dlstreamer-realsense</pre> |  docker images command to show <b>sdlstreamer:realsense</b>  |

!!! Warning
    Build command may take a while, depending on your internet connection and machine specifications.

!!! Note
    If the build command succeeds, you will see all the built Docker images files as indicated in the **Check Success** column. If the build fails, check the console output for errors. The dependencies might have been unable to resolve. Address the issue and repeat [step 2](/pipelinesetup.md#step-2).

!!! Proxy
    If the docker build system requires a proxy network, just set your proxy env standard way on your terminal as below and make build:
    ```bash
    export HTTP_PROXY="http://your-proxy-url.com:port"
    export HTTPS_PROXY="https://your-proxy-url.com:port"
    make build-all
    ```

## Next Steps

Run a [pipeline](./pipelinerun.md) or run a [benchmark for a pipeline](./pipelinebenchmarking.md).
