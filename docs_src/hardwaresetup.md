# Set up Hardware

=== "11th/12th Gen Intel® Core™ Processor"
    1. Download [Ubuntu 20.04](https://releases.ubuntu.com/focal/) and follow these [installation steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview).

    2. Install [Docker* Engine](https://docs.docker.com/engine/install/ubuntu/)

        !!! Note
            To avoid typing `sudo` when running the Docker command, follow these [steps](https://docs.docker.com/engine/install/linux-postinstall/).

    3. [Set up the pipeline](./pipelinesetup.md)

=== "Intel® Xeon® Processor"
    1. Download [Ubuntu 22.04](https://releases.ubuntu.com/22.04/) and follow these [installation steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview).

    2. Install [Docker Engine](https://docs.docker.com/engine/install/ubuntu/)

    3. [Set up the pipeline](./pipelinesetup.md)

=== "Intel® Data Center GPU Flex 140/170"
    1. Download [Ubuntu 22.04](https://releases.ubuntu.com/22.04/) and follow these [installation steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview).

    2. Update the [Kernel](https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-jammy-dc.html)
   
        !!! Warning
            After the kernel is updated, `apt-get install` might not work due to the unsupported kernel versions that were installed. To resolve this issue, do the following:
           
            1. Find all the installed kernels
       
                ```bash
                    dpkg --list | grep -E -i --color 'linux-image|linux-headers'
                ```
            2. Then remove the unsupported kernels. The example below will remove the installed kernel 5.19:
       
                ```bash
                    sudo apt-get purge -f 'linux--5.19'
                ```
   
    3. Install [Docker Engine](https://docs.docker.com/engine/install/ubuntu/)
   
    4. [Set up the pipeline](./pipelinesetup.md)

=== "Intel® Arc™"

    1. Download [Ubuntu 20.04](https://releases.ubuntu.com/focal/) and follow these [installation steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview).

    2. Update the [Kernel](https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-focal-arc.html)

        !!! Warning
            After the kernel is updated, `apt-get install` might not work due to the unsupported kernel versions that were installed. To resolve this issue, do the following:
    
            1. Find all the installed kernels
    
                ```bash
                    dpkg --list | grep -E -i --color 'linux-image|linux-headers'
                ```
            2. Then remove the unsupported kernels. The example below will remove the installed kernel 5.19:
    
                ```bash
                    sudo apt-get purge -f 'linux--5.19'
                ```

    3. Install [Docker Engine](https://docs.docker.com/engine/install/ubuntu/)

    4. [Set up the pipeline](./pipelinesetup.md)
