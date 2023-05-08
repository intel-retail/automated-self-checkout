# Setup for Hardware

## 11th & 12th Gen Intel® Core™ Setup

### Step 1: Install Ubuntu 20.04

Ubuntu [20.04](https://releases.ubuntu.com/focal/) following these [steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview)

### Step 2: Install Docker

Install Docker Engine using these [steps](https://docs.docker.com/engine/install/ubuntu/)

### Step 3: Pipeline Setup

Once complete continue to [Pipeline Setup](./pipelinesetup.md) for pipeline setup

---

### Xeon Setup

### Step 1: Install Ubuntu 22.04

Ubuntu [22.04](https://releases.ubuntu.com/22.04/) following these [steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview)

### Step 2: Install Docker

Install Docker Engine using these [steps](https://docs.docker.com/engine/install/ubuntu/)

### Step 3: Pipeline Setup

Once complete continue to [Pipeline Setup](./pipelinesetup.md) for pipeline setup

---

## Intel® Data Center GPU Flex 140 & 170 Setup

### Step 1: Install Ubuntu 22.04

Ubuntu [22.04](https://releases.ubuntu.com/22.04/) following these [steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview)

### Step 2: Kernel Update

Follow Intel Data Center GPU Flex Series install instructions [steps](https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-jammy-dc.html)

!!! note:
    After the kernel update, `apt-get install` may no longer work due to unsupported installed kernel versions.
    To resolve this issue please execute the following steps:

```bash
        # Find all installed kernels 
        dpkg --list | grep -E -i --color 'linux-image|linux-headers'

        # Then remove the unsupported kernels, the below example will remove the installed kernel 5.19:
        sudo apt-get purge -f 'linux--5.19'
```

### Step 3: Install Docker

Install Docker Engine using these [steps](https://docs.docker.com/engine/install/ubuntu/)

### Step 4: Pipeline Setup

Once complete continue to [Pipeline Setup](./pipelinesetup.md) for pipeline setup

---

## Intel® Arc™ Setup

### Step 1: Install Ubuntu 20.04

Ubuntu [20.04](https://releases.ubuntu.com/focal/) following these [steps](https://ubuntu.com/tutorials/install-ubuntu-desktop#1-overview)

### Step 2: Kernel Update

Follow the Arc kernel install [steps](https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-focal-arc.html)

!!! note:
    After the kernel update, `apt-get install` may no longer work due to unsupported installed kernel versions.
    To resolve this issue please execute the following steps:

```bash
        # Find all installed kernels 
        dpkg --list | grep -E -i --color 'linux-image|linux-headers'

        # Then remove the unsupported kernels, the below example will remove the installed kernel 5.19:
        sudo apt-get purge -f 'linux--5.19'
```

### Step 3: Install Docker

Install Docker Engine using these [steps](https://docs.docker.com/engine/install/ubuntu/)

### Step 4: Pipeline Setup

Once complete continue to [Pipeline Setup](./pipelinesetup.md) for pipeline setup
