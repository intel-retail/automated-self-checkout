# Vision Self Checkout

## Introduction
This guide helps you build and run the Vision Self Checkout solution.

Upon completing the steps in this guide, you will be ready to run and benchmark pipelines on different hardware setups.

### Overview

The Vision Self Checkout solution is a set of pre-configured pipelines that are optimized for performance on Intel. The pipelines run several models including yolov5s, efficientnet-b0, horizontal-test-detection-002, and text-recognitiion-0012-gpu. Details about the pipelines and how to run them can be found [HERE](./pipelinesetup.md)

A set of branchmarking tools have been provided to demonstrate the performance of the pipelines on Intel hardware. Once you have completed the [pipeline setup steps](./pipelinesetup.md) you will be able to run benchmark by following these [steps](./benchmark.md) 

[![Vision Self Checkout Diagram](./images/vision-checkout-1.0.png)](./images/vision-checkout-1.0.png)

### Prerequisites

The following items are required to build the Vision Self Checkout solution. You will need to follow the guide that matches your specific hardware setup.

- Ubuntu LTS Boot Device
- Docker
- GIT

### Installation and Pipeline Setup

Setup steps for each supported hardware can be found [HERE](./hardwaresetup.md)

    Certain third-party software or hardware identified in this document only may be used upon securing a license directly from the third-party software or hardware owner. The identification of non-Intel software, tools, or services in this document does not constitute a sponsorship, endorsement, or warranty by Intel.

    GStreamer is an open source framework licensed under LGPL. See https://gstreamer.freedesktop.org/documentation/frequently-asked-questions/licensing.html?gi-language=c.  You are solely responsible for determining if your use of Gstreamer requires any additional licenses.  Intel is not responsible for obtaining any such licenses, nor liable for any licensing fees due, in connection with your use of Gstreamer.

### Releases

Project release notes can be found on the github repo release site [HERE](https://github.com/intel-retail/vision-self-checkout/releases)
