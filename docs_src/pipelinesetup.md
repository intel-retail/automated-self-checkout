# Pipeline Setup

## Step 1: Clone the repository

```
git clone  https://github.com/intel-retail/automated-self-checkout.git && cd ./automated-self-checkout
```

## Step 2: Build Benchmark Containers

For benchmarking supported use cases you will need to build the benchmark containers

```bash
cd benchmark-scripts
make build-all
```

## Step 3: Download Models Manually (Optional)

Model downloader script is automatically called as part of docker-run.sh.  User can also download the models manually using the model downloader script shown as follows:

```bash
sh /download_models/getModels.sh --workload dlstreamer
```

!!! note
    This may take a while as there are several models to be downloaded for the first time.

!!! note
    To manually download models you can follow links provided in the [Model List](../configs/models/2022/models.list.yml)

## Step 4: Build the reference design Docker images

You must build the provided component services and create local docker images. Depending on platforms/hardware you have, refer to the following table to choose one to build:

| Platform                                   | Docker Build Command       | Check Success                                     |
| ------------------------------------------ | -------------------------- |---------------------------------------------------|
| Intel platforms with Intel integrated GPUs | <pre>make build-soc</pre>  | docker images command to show <b>sco-soc:2.0</b>  |
| Intel platforms with Intel discrete GPUs   | <pre>make build-dgpu</pre> | docker images command to show <b>sco-dgpu:2.0</b> |
| build both platforms                       | <pre>make build-all</pre>  | docker images command to show both above          |

!!! note
    Build command may take a while to run depending on your internet connection and machine specifications.

!!! note
    If you do not see all of the built docker image files as indicated in `Check Success` column, the build command most likely failed.  Please look through the console output for errors. Sometimes dependencies fail to resolve and must be run again. Address obvious issues. To try it again, repeat step 2 above.

!!! build with proxy information:
    If docker build system requires a proxy network, just set your proxy env standard way on your terminal as below and make build:
```bash
export HTTP_PROXY="http://your-proxy-url.com:port"
export HTTPS_PROXY="https://your-proxy-url.com:port"
make build-all
```



#### Next

Run a [use case/pipeline](./pipelinerun.md) or run a [benchmark for a use case/pipeline](./pipelinebenchmarking.md)
