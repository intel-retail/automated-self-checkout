# Advanced Settings

## Applying Environment Variables to Run Pipeline

EV can be applied in two ways:

    1. As a Docker Compose environment parameter input 
    2. In the env files

The input parameter will override the one in the env files if both are used.

### Run with custom environment variables

Environment variables with make commands

!!! Example

    ```bash
    make PIPELINE_SCRIPT=yolov5s_effnetb0.sh RESULTS_DIR="../render_results"  run-render-mode
    ```

Environment variable with docker compose up

!!! Example

    ```bash
    PIPELINE_SCRIPT=yolov5s_effnetb0.sh RESULTS_DIR="../render_results" docker compose -f src/docker-compose.yml --env-file src/res/yolov5-cpu.env up -d
    ```

!!! Note
        The environment variables set like this are known as command line environment overrides and are applied to this run only.
        They will override the default values in env files and docker-compose.yml.

### Editing the Environment Files

Environment variable files can be used to persist environment variables between deployments. There are three environment variables files with our default environment variables for Automated Self Checkout.

        - `src/gst.env` file for shared environment variables
        - `src/yolov5-cpu.env` file for running pipeline on cpu only
        - `src/yolov5-gpu.env` file for running pipeline in gpu or mixed CPU/GPU

After modifying or creating a new .env file you can load the .env file through docker compose up

!!! Example

    ```bash
    docker compose -f src/docker-compose.yml --env-file src/res/yolov5-cpu.env up -d
    ```

## Environment Variables (EVs)

The table below lists the environment variables (EVs) that can be used as inputs for the container running the inferencing pipeline.

=== "Docker Compose EVs"
    This list of EVs is for running through the make file or docker compose up

    | Variable | Description | Values |
    |:----|:----|:---|
    |`DEVICE_ENV` | Path to device specific environment file that will be loaded into the pipeline container | src/res/yolov5-gpu.env |
    |`DEVICE` | for setting device to use for pipeline run | "GPU", "CPU", "AUTO", "MULTI:GPU,CPU" |
    |`DOCKER_COMPOSE` | The docker-compose.yml file to run | src/docker-compose.yml |
    |`RETAIL_USE_CASE_ROOT` | The root directory for Automated Self Checkout in relation to the docker-compose.yml | .. |
    |`RESULTS_DIR` | Directory to output results | ../results |

=== "Docker Compose Parameters"
    This list of parameters that can be set when running docker compose up

    | Variable | Description | Values |
    |:----|:----|:---|
    |`-v` | Volume binding for containers in the Docker Compose | -v results/:/tmp/results |
    |`-e` | Override environment variables inside of the Docker Container | -e LOG_LEVEL debug |

=== "Common EVs"
    This list of EVs is common for all profiles.

    | Variable | Description | Values |
    |:----|:----|:---|
    |`BARCODE_RECLASSIFY_INTERVAL` | time interval in seconds for barcode classification | Ex: 5 |
    |`BATCH_SIZE` | number of frames batched together for a single inference to be used in [gvadetect batch-size element](https://dlstreamer.github.io/elements/gvadetect.html) | 0, 1 |
    |`CLASSIFICATION_OPTIONS` | extra classification pipeline instruction parameters | "", "reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4" |
    |`DETECTION_OPTIONS` | extra object detection pipeline instruction parameters | "", "gpu-throughput-streams=4 nireq=4 batch-size=1" |
    |`GST_DEBUG` | for running pipeline in gst debugging mode | 0, 1 |
    |`LOG_LEVEL` | log level to be set when running gst pipeline | ERROR, INFO, WARNING, and [more](https://gstreamer.freedesktop.org/documentation/tutorials/basic/debugging-tools.html?gi-language=c#the-debug-log) |
    |`OCR_RECLASSIFY_INTERVAL` | time interval in seconds for OCR classification | Ex: 5 |
    |`RENDER_MODE` | for displaying pipeline and overlay CV metadata | 1, 0 |
    |`PIPELINE_COUNT` | Number of Automated Self Checkout Docker container instances to launch | Ex: 1 |
    |`PIPELINE_SCRIPT` | Pipeline script to run. | yolov5s.sh, yolov5s_effnetb0.sh, yolov5s_full.sh |

=== "Automated Self Checkout DLStreamer EVs"
    This list of EVs specifically supports the GST profile DLStreamer workloads.

    | Variable | Description | Values |
    |:----|:----|:---|
    |`DECODE` | decoding element instructions for gst-launch to use | Ex: "decode bin force-sw-decoders=1" |
    |`OCR_DEVICE` | optical character recognition device | "CPU", "GPU" |
    |`PRE_PROCESS` | pre process command to add for inferencing | "pre-process-backend=vaapi-surface-sharing", "pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1" |
    |`VA_SURFACE` | use video analytics surface from the shared memory if applicable | "", "! "video/x-raw(memory |VASurface)" (GPU only)" |
