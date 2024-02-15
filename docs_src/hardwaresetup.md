# System Setup

## Prerequisites

To build the Intel® Automated Self-Checkout Reference Package, you need:

- [Ubuntu LTS](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview) ([22.04](https://releases.ubuntu.com/22.04/))
- [Docker](https://docs.docker.com/engine/install/ubuntu/) (Tested on version >= 23.0.0)
- [Docker Compose v2](https://docs.docker.com/compose/) (Required, if using docker compose feature)
- [Git](https://git-scm.com/download/linux)
- Make - install with `apt install make`

Click the links for corresponding set up instructions.

## Hardware Dependent Installation

=== "11th/12th Gen Intel® Core™ Processor, Intel® Arc™, Intel® Xeon® Processor"
    1. Download [Ubuntu 22.04](https://releases.ubuntu.com/22.04/) and follow these [installation steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview).

    2. Install [Docker* Engine](https://docs.docker.com/engine/install/ubuntu/)

        !!! Note
            To avoid typing `sudo` when running the Docker command, follow these [steps](https://docs.docker.com/engine/install/linux-postinstall/).
    
    3. [**Optional**] Install [Docker Compose v2](https://docs.docker.com/compose/), if using the docker compose feature
    
    4. Install [Git](https://git-scm.com/download/linux)

    3. [Set up the pipeline](./OVMS/pipelinesetup.md)

=== "Intel® Data Center GPU Flex 140/170"
    1. Download [Ubuntu 22.04](https://releases.ubuntu.com/22.04/) and follow these [installation steps](https://dgpu-docs.intel.com/driver/installation.html#ubuntu-install-steps).
   
    3. Install [Docker Engine](https://docs.docker.com/engine/install/ubuntu/)

    3. [**Optional**] Install [Docker Compose v2](https://docs.docker.com/compose/), if using the docker compose feature
    
    4. Install [Git](https://git-scm.com/download/linux)
 
    4. [Set up the pipeline](./OVMS/pipelinesetup.md)
