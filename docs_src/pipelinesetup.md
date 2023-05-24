# Pipeline Setup

## Step 1: Clone the repository

```
git clone  https://github.com/intel-retail/automated-self-checkout.git && cd ./automated-self-checkout
```

## Step 2: Build Benchmark Containers

For benchmarking supported use cases you will need to build the benchmark containers

```bash
make build-all
```

## Step 3: Download Models Manually (Optional)

Model downloader script is automatically called as part of docker-run.sh.  User can also download the models manually using the model downloader script shown as follows:

```bash
sh modelDownload.sh
```

!!! note
    This may take a while as there are several models to be downloaded for the first time.

!!! note
    To manually download models you can follow links provided in the [Model List](../configs/models/2022/models.list.yml)

## Step 4: Build the reference design Docker images

You must build the provided component services and create local docker images. Depending on platforms/hardware you have, refer to the following table to choose one to build:

| Platform                                   | Docker Build Command      | Check Success                                |  
| ------------------------------------------ | ------------------------- |----------------------------------------------|
| Intel platforms with Intel integrated GPUs | <pre>./docker-build.sh soc</pre>  | docker images command to show <b>sco-soc:2.0</b>  |
| Intel platforms with Intel discrete GPUs   | <pre>./docker-build.sh dgpu</pre> | docker images command to show <b>sco-dgpu:2.0</b> |

!!! note
    Build command may take a while to run depending on your internet connection and machine specifications.

!!! note
    If you do not see all of the built docker image files as indicated in `Check Success` column, the build command most likely failed.  Please look through the console output for errors. Sometimes dependencies fail to resolve and must be run again. Address obvious issues. To try it again, repeat step 2 above.

!!! build with proxy information:
    If docker build system requires a proxy network, please provide the proxy URL after the first argument.  For example, to build the reference design docker image with the proxy information:
```bash
./docker-build.sh <soc|dgpu> http://http_proxy_server_ip:http_proxy_server_port http(s)://https_proxy_server_ip:https_proxy_server_port
```

#### Next

Run a [use case/pipeline](./pipelinerun.md) or run a [benchmark for a use case/pipeline](./pipelinebenchmarking.md)
