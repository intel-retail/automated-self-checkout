# Automated Self Checkout

![Integration](https://github.com/intel-retail/automated-self-checkout/actions/workflows/integration.yaml/badge.svg?branch=main)
![CodeQL](https://github.com/intel-retail/automated-self-checkout/actions/workflows/codeql.yaml/badge.svg?branch=main)
![GolangTest](https://github.com/intel-retail/automated-self-checkout/actions/workflows/gotest.yaml/badge.svg?branch=main)
![DockerImageBuild](https://github.com/intel-retail/automated-self-checkout/actions/workflows/build.yaml/badge.svg?branch=main) 
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/intel-retail/automated-self-checkout/badge)](https://api.securityscorecards.dev/projects/github.com/intel-retail/automated-self-checkout)
[![GitHub Latest Stable Tag](https://img.shields.io/github/v/tag/intel-retail/automated-self-checkout?sort=semver&label=latest-stable)](https://github.com/intel-retail/automated-self-checkout/releases)
[![Discord](https://discord.com/api/guilds/1150892043120414780/widget.png?style=shield)](https://discord.gg/2SpNRF4SCn)

> **Warning**  
> The **main** branch of this repository contains work-in-progress development code for the upcoming release, and is **not guaranteed to be stable or working**.
>
> **The source for the latest release can be found at [Releases](https://github.com/intel-retail/automated-self-checkout/releases).**

# Table of Contents 📑

- [📋 Prerequisites](#-prerequisites)
- [🚀 QuickStart](#-quickstart)
  - [Run pipeline on iGPU](#run-pipeline-on-igpu)
  - [Run pipeline with classification model on iGPU](#run-pipeline-with-classification-model-on-igpu)
- [📊 Benchmarks](#-benchmarks)
- [📖 Advanced Documentation](#-documentation)
- [🌀 Join the community](#-join-the-community)
- [References](#references)
- [Disclaimer](#disclaimer)
- [Datasets & Models Disclaimer](#datasets--models-disclaimer)
- [License](#license)

## 📋 Prerequisites

- Ubuntu 24.04 / 24.10
- [Docker](https://docs.docker.com/engine/install/ubuntu/) 
- [Manage Docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/)
- Make (sudo apt install make)
- Intel hardware (CPU, iGPU, dGPU, NPU)
- Intel drivers
  - Lunar Lake iGPU: https://dgpu-docs.intel.com/driver/client/overview.html
  - NPU: https://medium.com/openvino-toolkit/how-to-run-openvino-on-a-linux-ai-pc-52083ce14a98 


## 🚀 QuickStart

Clone the repo with the below command
```
git clone -b <release-or-tag> --single-branch https://github.com/intel-retail/automated-self-checkout
```
>Replace <release-or-tag> with the version you want to clone (for example, **v2.0.0**).
```
git clone -b v2.0.0 --single-branch https://github.com/intel-retail/automated-self-checkout
```

### **NOTE:** 

By default the application runs by pulling the pre-built images. If you want to build the images locally and then run the application, set the flag:

```bash
REGISTRY=false

usage: make <command> REGISTRY=false (applicable for all commands like benchmark, benchmark-stream-density..)
Example: make run-demo REGISTRY=false
```

(If this is the first time, it will take some time to download videos, models, docker images and build images)

### Step by step instructions:

1. Download the models using download_models/downloadModels.sh

    ```bash
    make download-models
    ```

2. Update github submodules

    ```bash
    make update-submodules
    ```

3. Download sample videos used by the performance tools

    ```bash
    make download-sample-videos
    ```

4. Start Automated Self Checkout using the Docker Compose file. 

    ```bash
    make run-render-mode
    ```

- The above series of commands can be executed using only one command:
    
    ```bash
    make run-demo
    ```

stop containers:

```
make down
```

### Run pipeline on iGPU

```
DEVICE_ENV=res/all-gpu.env make run-demo
```

```
make down
```

### Run pipeline with classification model on iGPU

```
PIPELINE_SCRIPT=yolo11n_effnetb0.sh DEVICE_ENV=res/all-gpu.env make run-demo
```

### Run pipeline after building local images

```
make run-demo REGISTRY=false
```


## 📊 Benchmarks 

- [Benchmark Commands](./benchmark-commands.md)

## 📖 Advanced Documentation

- [Automated Self-Checkout Documentation Guide](https://intel-retail.github.io/documentation/use-cases/automated-self-checkout/automated-self-checkout.html)  

## 🌀 Join the community 
[![Discord Banner 1](https://discordapp.com/api/guilds/1150892043120414780/widget.png?style=banner2)](https://discord.gg/2SpNRF4SCn)

## References

- [Developer focused website to enable developers to engage and build our partner community](https://www.intel.com/content/www/us/en/developer/articles/reference-implementation/automated-self-checkout.html)

- [LinkedIn blog illustrating the automated self checkout use case more in detail](https://www.linkedin.com/pulse/retail-innovation-unlocked-open-source-vision-enabled-mohideen/)

## Disclaimer

GStreamer is an open source framework licensed under LGPL. See https://gstreamer.freedesktop.org/documentation/frequently-asked-questions/licensing.html?gi-language=c.  You are solely responsible for determining if your use of Gstreamer requires any additional licenses.  Intel is not responsible for obtaining any such licenses, nor liable for any licensing fees due, in connection with your use of Gstreamer.

Certain third-party software or hardware identified in this document only may be used upon securing a license directly from the third-party software or hardware owner. The identification of non-Intel software, tools, or services in this document does not constitute a sponsorship, endorsement, or warranty by Intel.

## Datasets & Models Disclaimer

To the extent that any data, datasets or models are referenced by Intel or accessed using tools or code on this site such data, datasets and models are provided by the third party indicated as the source of such content. Intel does not create the data, datasets, or models, provide a license to any third-party data, datasets, or models referenced, and does not warrant their accuracy or quality.  By accessing such data, dataset(s) or model(s) you agree to the terms associated with that content and that your use complies with the applicable license.

Intel expressly disclaims the accuracy, adequacy, or completeness of any data, datasets or models, and is not liable for any errors, omissions, or defects in such content, or for any reliance thereon. Intel also expressly disclaims any warranty of non-infringement with respect to such data, dataset(s), or model(s). Intel is not liable for any liability or damages relating to your use of such data, datasets or models.

## License
This project is Licensed under an Apache [License](./LICENSE.md).
