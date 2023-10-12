# Set up Hardware

## Set up 11th Gen Intel® Core™ Processor and 12th Gen Intel® Core™ Processor

### Step 1: Install Ubuntu* 20.04

Download [Ubuntu 20.04](https://releases.ubuntu.com/focal/) and follow these [installation steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview).

### Step 2: Install [Docker* Engine](https://docs.docker.com/engine/install/ubuntu/)

To avoid typing `sudo` when running the Docker command, follow these [steps](https://docs.docker.com/engine/install/linux-postinstall/).

### Step 3: [Set up the pipeline](./pipelinesetup.md)

---

## Set up Intel® Xeon® Processor

### Step 1: Install Ubuntu 22.04

Download [Ubuntu 22.04](https://releases.ubuntu.com/22.04/) and follow these [installation steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview).

### Step 2: Install [Docker Engine](https://docs.docker.com/engine/install/ubuntu/)

### Step 3: [Set up the pipeline](./pipelinesetup.md)


---

## Set up Intel® Data Center GPU Flex 140 and Intel® Data Center GPU Flex 170

### Step 1: Install Ubuntu 22.04

Download [Ubuntu 22.04](https://releases.ubuntu.com/22.04/) and follow these [installation steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview).

### Step 2: Update the [Kernel](https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-jammy-dc.html)

!!! Warning
    After the kernel is updated, `apt-get install` might not work due to the unsupported kernel versions that were installed. To resolve this issue,
    do the following:
    
    1. Find all the installed kernels

        ```bash
            dpkg --list | grep -E -i --color 'linux-image|linux-headers'
        ```
    2. Then remove the unsupported kernels. The example below will remove the installed kernel 5.19:

        ```bash
            sudo apt-get purge -f 'linux--5.19'
        ```

### Step 3: Install [Docker Engine](https://docs.docker.com/engine/install/ubuntu/)

### Step 4: [Set up the pipeline](./pipelinesetup.md)

---

## Set up Intel® Arc™

### Step 1: Install Ubuntu 20.04

Download [Ubuntu 20.04](https://releases.ubuntu.com/focal/) and follow these [installation steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview).

### Step 2: Update the [Kernel](https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-focal-arc.html)

!!! Warning
    After the kernel is updated, `apt-get install` might not work due to the unsupported kernel versions that were installed. To resolve this issue,
    do the following:

    1. Find all the installed kernels

        ```bash
            dpkg --list | grep -E -i --color 'linux-image|linux-headers'
        ```
    2. Then remove the unsupported kernels. The example below will remove the installed kernel 5.19:

        ```bash
            sudo apt-get purge -f 'linux--5.19'
        ```

### Step 3: Install [Docker Engine](https://docs.docker.com/engine/install/ubuntu/)

### Step 4: [Set up the pipeline](./pipelinesetup.md)
