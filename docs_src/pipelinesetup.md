# Set up Pipeline

### Step 1: Clone the repository

```
git clone  https://github.com/intel-retail/automated-self-checkout.git && cd ./automated-self-checkout
```

### Step 2: Build the benchmark containers

For use cases that support benchmarking, build the benchmark containers:

```bash
make build-all
```

### Step 3: Download the models manually (Optional)

When `docker-run.sh` the Model downloader script is automatically called. You can also download the models manually using the model downloader script:

```bash
sh modelDownload.sh
```

**_Note:_**  This step might take a while as the script will download several models for the first time.

**_Note:_**  To manually download the models, see the links in [Model List](../configs/models/2022/models.list.yml).

### Step 4: Build the reference design Docker* images

You must build the provided component services and create local docker images. The following table lists the build command for various platforms. Choose and run the command corresponding to your platforms or hardware.

| Platform                                   | Docker Build Command              | Check Success                                     |  
| ------------------------------------------ | ----------------------------------|---------------------------------------------------|
| Intel platforms with Intel integrated GPUs | <pre>./docker-build.sh soc</pre>  | docker images command to show <b>sco-soc:2.0</b>  |
| Intel platforms with Intel discrete GPUs   | <pre>./docker-build.sh dgpu</pre> | docker images command to show <b>sco-dgpu:2.0</b> |

**_Note:_** Build command may take a while, depending on your internet connection and machine specifications.

**_Note:_** If the build command succeeds, you will see all the built Docker images files as indicated in the **Check Success** column. If the build fails, check the console output for errors. The dependencies might have been unable to resolve. Address the issue and repeat [step 2](/pipelinesetup.md#step-2).

**Build with proxy**: If the Docker build system requires a proxy network, provide the proxy URL after the first argument. Here is an example to build the reference design Docker image with the proxy information:

```bash
./docker-build.sh <soc|dgpu> http://http_proxy_server_ip:http_proxy_server_port http(s)://https_proxy_server_ip:https_proxy_server_port
```

## Next Steps

Run a [use case or pipeline](./pipelinerun.md) or run a [benchmark for a use case or pipeline](./pipelinebenchmarking.md).
