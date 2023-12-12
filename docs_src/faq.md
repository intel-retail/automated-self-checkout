# Frequently Asked Questions

## What are the platform requirements?

For optimal hardware, refer to the [platform guide](./platforms.md).

## What are the software prerequisites?

At a minimum, you will need Docker* 23.0 or later. For more details, refer to the [hardware setup](./hardwaresetup.md).

## How do I download the models?

The models are downloaded automatically when the benchmark script `benchmark.sh` is run. For more details on downloading models, refer to [Set up Pipeline](./pipelinesetup_dlstreamer.md#step-4-build-the-reference-design-docker-images).

## How do I simulate RTSP cameras?

You can use the camera simulator script `camera-simulator.sh` to run simulated RTSP camera streams. For more details on the script, refer to [Run Pipeline](./pipelinerun.md#run-camera-simulator) page.

## How do I download video files for benchmarking?

You can download your own media file or use the the provided `download_sample_videos.sh` script to download an existing media file. For more details, refer to [Benchmark Pipeline](./pipelinebenchmarking.md#file).

## How do I run different types of pipelines?

For details on running different types of pipelines, refer to [Benchmark Pipeline](./pipelinebenchmarking.md#additional-benchmark-examples).

## Where are the pipeline container logs located ?

Pipeline container logs are redirected to a text file at `automated-self-checkout/results`. For every new pipeline a new log file `pipeline##.log` is created.

!!! Note
    As pipeline container logs are redirected to separate text files, docker logs displayed using portainer or command `docker logs <**CONTAINER**>` will be empty.