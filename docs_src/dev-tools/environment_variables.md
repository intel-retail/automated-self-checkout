# Environment Variables (EVs)
The table below lists the environment variables (EVs) that can be used as inputs for the container running the inferencing pipeline.

=== "GST profile EVs"
    This list of EVs specifically supports the GST profile DLStreamer workloads.

    | Variable | Description | Values |
    |:----|:----|:---|
    |`AGGREGATE` | aggregate branches of the gstreamer pipeline, if any, at the end of the pipeline | "", "gvametaaggregate name=aggregate", "aggregate branch. ! queue" |
    |`BARCODE_RECLASSIFY_INTERVAL` | time interval in seconds for barcode classification | Ex: 5 |
    |`CLASSIFICATION_OPTIONS` | extra classification pipeline instruction parameters | "", "reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4" |
    |`CPU_SW_DECODER` | force to use software decoder for gst-launch decoding video frames in CPU | "force-sw-decoders=1" |
    |`DECODE` | decoding element instructions for gst-launch to use | Ex: "decode bin force-sw-decoders=1" |
    |`DETECTION_OPTIONS` | extra object detection pipeline instruction parameters | "", "gpu-throughput-streams=4 nireq=4 batch-size=1" |
    |`GST_DEBUG` | for running pipeline in gst debugging mode | 0, 1 |
    |`GST_PIPELINE_LAUNCH` | for launching gst pipeline script file path and name | Ex: "/home/pipeline-server/pipelines/yolov5_pipeline/yolov5s_full.sh" |
    |`LOG_LEVEL` | log level to be set when running gst pipeline | ERROR, INFO, WARNING, and [more](https://gstreamer.freedesktop.org/documentation/tutorials/basic/debugging-tools.html?gi-language=c#the-debug-log) |
    |`OCR_RECLASSIFY_INTERVAL` | time interval in seconds for OCR classification | Ex: 5 |
    |`PARALLEL_PIPELINE` | run pipeline in parallel using the tee branch | "", "! tee name=branch ! queue" |
    |`PARALLEL_AGGRAGATE` | aggregate parallel pipeline results together, paired use with PARALLEL_PIPELINE | "", "! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose branch. ! queue !" |
    |`VA_SURFACE` | use video analytics surface from the shared memory if applicable | "", "! "video/x-raw(memory |VASurface)" (GPU only)" |
    |`BATCH_SIZE` | number of frames batched together for a single inference to be used in [gvadetect batch-size element](https://dlstreamer.github.io/elements/gvadetect.html) | 0, 1 |

=== "Common EVs"
    This list of EVs is common for all profiles.

    | Variable | Description | Values |
    |:----|:----|:---|
    |`AUTO_SCALE_FLEX_140` | allow workload to manage autoscaling | 1, 0 |
    |`CPU_ONLY` | for overriding inference to be performed on CPU only | 1, 0 |
    |`DEVICE` | for setting device to use for pipeline run | "GPU", "CPU", "AUTO", "MULTI:GPU,CPU" |
    |`LOW_POWER` | for running pipelines using GPUs only | 1, 0 |
    |`OCR_DEVICE` | optical character recognition device | "CPU", "GPU" |
    |`PRE_PROCESS` | pre process command to add for inferencing | "pre-process-backend=vaapi-surface-sharing", "pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1" |
    |`PIPELINE_PROFILE` | for choosing OVMS workload's pipeline profile to run | use `make list-profiles` to see Values |
    |`RENDER_MODE` | for displaying pipeline and overlay CV metadata | 1, 0 |
    |`STREAM_DENSITY_MODE` | for starting pipeline stream density testing | 1, 0 |
    |`STREAM_DENSITY_FPS` | for setting stream density target fps value | Ex: 15.0 |
    |`STREAM_DENSITY_INCREMENTS` |for setting incrementing number of pipelines for running stream density| Ex: 1 |

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