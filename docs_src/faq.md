# FAQ

## What are the platform requirements?

11th gen Intel processors or newer are supported but may not be optimal. For optimal setups see the [platform guide](./platforms.md)

## What are the Software Pre-Requisites?

At a minimum you will need Docker version 23 or later. Please see [hardware setup](./hardwaresetup.md) for more details.

## How do I download the models?

Downloading the required models will automatically happen when running the benchmark.sh. More details about download models can be found on the [pipeline setup page](./pipelinesetup.md#step-4-build-the-reference-design-docker-images).

## How do I simulate RTSP cameras?

The camera simulator script is the best way to run simulated RTSP camera streams. Details about the script can be found on the [pipeline run](./pipelinerun.md#run-camera-simulator) page.

## How do I download video files for benchmarking?

You can download your own media file or use the provided download_sample_videos.sh to download an existing media file. Details about running the script can be found on the [pipeline benchmarking](./pipelinebenchmarking.md#file) page.

## How do I run different types of pipelines?

Details about different benchmark pipelines can be found on the [pipeline benchmarking](./pipelinebenchmarking.md#additional-benchmark-examples) page