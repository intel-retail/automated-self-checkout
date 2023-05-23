# Pipeline Setup

## Step 1: Clone the repository

```
git clone  https://github.com/intel-retail/vision-self-checkout.git && cd ./vision-self-checkout
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
    To manually download models you can follow links provided in the [Model List](../configs/models/2022/models.list.yml)

## Step 4: Build the reference design Docker images

You must build the provided component services and create local docker images. To do so, run:

For Intel Core platforms
```bash
./docker-build.sh soc
```

For Intel platforms with Intel discrete GPUs
```bash
./docker-build.sh dgpu
```

For Intel platforms with Intel integrated GPUs
```bash
cd benchmark-scripts
make build-benchmark
make build-igt
```

For Intel platforms with Intel discrete GPUs
```bash
cd benchmark-scripts
make build-xpu
```

!!! note:
    This command may take a while to run depending on your internet connection and machine specifications.

!!! build with proxy information:
    If docker build system requires a proxy network, please provide the proxy URL after the first argument.  For example, build the reference design docker image with the proxy information for Core systems:
```bash
./docker-build.sh soc http://http_proxy_server_ip:http_proxy_server_port http(s)://https_proxy_server_ip:https_proxy_server_port
```

Similarly for building with the proxy information for DGPU systems:

```bash
./docker-build.sh dgpu http://http_proxy_server_ip:http_proxy_server_port http(s)://https_proxy_server_ip:https_proxy_server_port
```

#### Check for success

Make sure the command was successful. To do so, run:

```
docker images
```

!!! success 
    The results are:

    - `sco-soc      2.0`
    or
    - `sco-dgpu     2.0`
    or
    - `igt          latest`

!!! failure
    If you do not see all of the above docker image files, look through the console output for errors. Sometimes dependencies fail to resolve and must be run again. Address obvious issues. To try again, repeat step 2.


#### Next

Run a [use case/pipeline](./pipelinerun.md) or run a [benchmark for a use case/pipeline](./pipelinebenchmarking.md)
