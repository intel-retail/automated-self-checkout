# Environment Variables (EVs)
The table below lists the environment variables (EVs) that can be used as inputs for the container running the inferencing pipeline.

| Variable | Description | Values |
|:----|:----|:---|
|`PIPELINE_PROFILE` | for choosing OVMS workload's pipeline profile to run | use `make list-profiles` to see Values |
|`RENDER_MODE` | for displaying pipeline and overlay CV metadata | 1, 0 |
|`LOW_POWER` | for running pipelines using GPUs only | 1, 0 |
|`CPU_ONLY` | for overriding inference to be performed on CPU only | 1, 0 |
|`STREAM_DENSITY_MODE` | for starting pipeline stream density testing | 1, 0 |
|`STREAM_DENSITY_FPS` | for setting stream density target fps value | Ex: 15.0 |
|`STREAM_DENSITY_INCREMENTS` |for setting incrementing number of pipelines for running stream density| Ex: 1 |
|`AUTO_SCALE_FLEX_140` | allow workload to manage autoscaling | 1, 0 |
|`DEVICE` | for setting device to use for pipeline run | "GPU", "CPU", "AUTO", "MULTI |GPU,CPU" |
|`OCR_DEVICE` | optical character recognition device | "CPU", "GPU" |
|`PRE_PROCESS` | pre process command to add for inferencing | "pre-process-backend=vaapi-surface-sharing", "pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1" |

## Applying EV to Run Pipeline
EV can be applied in two ways:

    1. as parameter input to run.sh script
    2. in the env files

The input parameter will override the one in the env files if both are used.

### EV as input parameter

!!! Example - Environment Variable as an input parameter

    ```bash
    PIPELINE_PROFILE="object_detection" CPU_ONLY=1 RENDER_MODE=0 sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
    ```

    !!! Note
        Those EVs in front of run.sh like `CPU_ONLY`, `RENDER_MODE` are applied to this run only and they are also known as command line environment overrides, or environment overrides.  They will override the default values in env files if any.


### Editing the Env Files
EV can be configured for advanced user in `configs/opencv-ovms/envs/`.  As an example for gst pipeline profile, there are two Env files can be configured:

        - `yolov5-cpu.env` file for running pipeline in core system
        - `yolov5-gpu.env` file for running pipeline in gpu or multi

These two files currently hold the default values.