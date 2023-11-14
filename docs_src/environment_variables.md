# Environment Variable (EV)
We support environment variables (EVs) as inputs for container that runs inferencing pipeline, we categorize three types of EVs:

    1. EVs support dlstreamer workload only
    2. EVs support ovms workload only
    3. EVs support both

=== "EVs for DLStreamer"
    This list of EVs specifically supports DLStreamer workloads.

    | Variable | Description | Values |
    |:----|:----|:---|
    |`GST_PIPELINE_LAUNCH` | for launching gst pipeline script file path and name | Ex: "/home/pipeline-server/framework-pipelines/yolov5_pipeline/yolov5s.sh" |
    |`GST_DEBUG` | for running pipeline in gst debugging mode | 0, 1 |
    |`LOG_LEVEL` | log level to be set when running gst pipeline | ERROR, INFO, WARNING, and [more](https://gstreamer.freedesktop.org/documentation/tutorials/basic/debugging-tools.html?gi-language=c#the-debug-log) |
    |`AGGREGATE` | aggregate branches of the gstreamer pipeline, if any, at the end of the pipeline | "", "gvametaaggregate name=aggregate", "aggregate branch. ! queue" |
    |`OUTPUTFORMAT` | output format gstreamer instructions for the pipeline | "! fpsdisplaysink video-sink=fakesink sync=true --verbose", "(render_mode)! videoconvert ! video/x-raw,format=I420 ! gvawatermark ! videoconvert ! fpsdisplaysink video-sink=ximagesink sync=true --verbose" |
    |`VA_SURFACE` | use video analytics surface from the shared memory if applicable | "", "! "video/x-raw(memory |VASurface)" (GPU only)" |
    |`PARALLEL_PIPELINE` | run pipeline in parallel using the tee branch | "", "! tee name=branch ! queue" |
    |`PARALLEL_AGGRAGATE` | aggregate parallel pipeline results together, paired use with PARALLEL_PIPELINE | "", "! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose branch. ! queue !" |
    |`DETECTION_OPTIONS` | extra object detection pipeline instruction parameters | "", "gpu-throughput-streams=4 nireq=4 batch-size=1" |
    |`CLASSIFICATION_OPTIONS` | extra classification pipeline instruction parameters | "", "reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4" |


=== "EVs for OVMS"

    This list of EVs specifically supports OVMS workloads.

    | Variable | Description | Values |
    |:----|:----|:---|
    |`PIPELINE_PROFILE` | for choosing ovms workload's pipeline profile to run | use `make list-profiles` to see Values |

=== "EVs for Both"

    This list of EVs supports both DLStreamer and OVMS workloads.

    | Variable | Description | Values |
    |:----|:----|:---|
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
EV can be applied in two ways |

    1. as parameter input to run.sh script
    2. in the env files

The input parameter will override the one in the env files if both are used.

### EV as input parameter
EV as input parameter to pipeline run, here is an example |

```bash
CPU_ONLY=1 sudo -E ./run.sh --workload dlstreamer --platform core --inputsrc rtsp |//127.0.0.1 |8554/camera_0 --ocr_disabled --barc
ode_disabled
```

### Editing the Env Files
EV can be configured for advanced user in `configs/dlstreamer/framework-pipelines/yolov5_pipeline/`

        |`yolov5-cpu.env` file for running pipeline in core system
        |`yolov5-gpu.env` file for running pipeline in gpu or multi

these two files currently hold the default values.