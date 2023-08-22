# Environment Variable (EV)
We support environment variables (EVs) as inputs for container that runs inferencing pipeline, we categorize three types of EVs:

    1. EVs support dlstreamer workload only
    2. EVs support opencv-ovms workload only
    3. EVs support both

## EVs Support DLStreamer Workload Only
Here is the list of EVs that support dlstreamer workload pipeline run:

- `GST_PIPELINE_LAUNCH`: for launching gst pipeline script file path and name, value can be "/home/pipeline-server/framework-pipelines/yolov5_pipeline/yolov5s.sh".
- `GST_DEBUG`: for running pipeline in gst debugging mode, value can be 0, 1.
- `LOG_LEVEL`: log level to be set when running gst pipeline, value can be ERROR, INFO, WARNING, more options can be find in https://gstreamer.freedesktop.org/documentation/tutorials/basic/debugging-tools.html?gi-language=c#the-debug-log
- `AGGREGATE`: aggregate branches of the gstreamer pipeline, if any, at the end of the pipeline, value can be "", "gvametaaggregate name=aggregate", "aggregate branch. ! queue"
- `OUTPUTFORMAT`: output format gstreamer instructions for the pipeline, value can be "! fpsdisplaysink video-sink=fakesink sync=true --verbose", "(render_mode)! videoconvert ! video/x-raw,format=I420 ! gvawatermark ! videoconvert ! fpsdisplaysink video-sink=ximagesink sync=true --verbose".
- `VA_SURFACE`: use video analytics surface from the shared memory if applicable, value can be "", "! "video/x-raw(memory:VASurface)" (GPU only)".
- `PARALLEL_PIPELINE`: run pipeline in parallel using the tee branch, value can be "", "! tee name=branch ! queue".
- `PARALLEL_AGGRAGATE`: aggregate parallel pipeline results together, paired use with PARALLEL_PIPELINE, value can be "", "! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r$cid_count.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose branch. ! queue !".
- `DETECTION_OPTIONS`: extra object detection pipeline instruction parameters, value can be "", "gpu-throughput-streams=4 nireq=4 batch-size=1".
- `CLASSIFICATION_OPTIONS`: extra classification pipeline instruction parameters, value can be "", "reclassify-interval=1 batch-size=1 nireq=4 gpu-throughput-streams=4".

## EVs Support Open-ovms Workload Only
Here is the list of EVs specifically support opencv-ovms workload:

- `PIPELINE_PROFILE`: for choosing opencv-ovms workload's pipeline profile to run, values can be listed by `make list-profiles`.

## EVs Support Both workloads
Here is the list of EVs support both dlstreamer and opencv-ovms workloads:
- `RENDER_MODE`: for displaying pipeline and overlay CV metadata, value can be 1, 0.
- `LOW_POWER`: for using GPU usage only based pipeline for Core platforms, value can be 1, 0.
- `CPU_ONLY`: for overriding inference to be performed on CPU only, value can be 1, 0.
- `STREAM_DENSITY_MODE`: for starting pipeline stream density testing, value can be 1, 0.
- `STREAM_DENSITY_FPS`: for setting stream density target fps value, ex: 15.0.
- `STREAM_DENSITY_INCREMENTS`:for setting incrementing number of pipelines for running stream density, ex: 1.
- `AUTO_SCALE_FLEX_140`: allow workload to manage autoscaling, value can be 1, 0.
- `DEVICE`: for setting device to use for pipeline run, value can be "GPU", "CPU", "AUTO", "MULTI:GPU,CPU".
- `OCR_DEVICE`: optical character recognition device, value can be "CPU", "GPU".
- `PRE_PROCESS`: pre process command to add for inferencing, value can be "pre-process-backend=vaapi-surface-sharing", "pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1"

## Applying EV to Run Pipeline
EV can be applied in two ways:

    1. as parameter input to docker-run.sh script
    2. in the env files

The input parameter will override the one in the env files if both are used.

### EV as input parameter
EV as input parameter to pipeline run, here is an example:

```bash
CPU_ONLY=1 sudo -E ./docker-run.sh --workload dlstreamer --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --ocr_disabled --barc
ode_disabled
```

### Editing the Env Files
EV can be configured for advanced user in `configs/dlstreamer/framework-pipelines/yolov5_pipeline/`
    - `yolov5-cpu.env` file for running pipeline in core system
    - `yolov5-gpu.env` file for running pipeline in gpu or multi

these two files currently hold the default values.