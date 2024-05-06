# Getting Started

## Step by step instructions:

1. Download the models using download_models/downloadModels.sh

    ```bash
    make download-models
    ```

2. Update github submodules

    ```bash
    make update-submodules
    ```

3. Download sample videos used by the performance tools

    ```bash
    make download-sample-videos
    ```

4. Build the demo Docker image

    ```bash
    make build
    ```

5. Start Automated Self Checkout using the Docker Compose file. The Docker Compose also includes an RTSP camera simulator that will infinitely loop through the sample videos downloaded in step 3.

    ```bash
    make run-render-mode
    ```

6. Verify Docker containers

    Verify Docker images
    ```bash
    docker ps --format 'table{{.Image}}\t{{.Status}}'
    ```
    Result:
    ```bash
    src-OvmsClientGst-1   Up 32 seconds
    camera-simulator0     Up 4 minutes
    camera-simulator      Up 4 minutes
    ```

7. Verify Results

    After starting Automated Self Checkout you will begin to see result files being written into the results/ directory. Here are example outputs from the 3 log files.

    gst-launch_<time>_gst.log
    ```
    /GstPipeline:pipeline0/GstGvaWatermark:gvawatermark0/GstCapsFilter:capsfilter1: caps = video/x-raw(memory:VASurface), format=(string)RGBA
    /GstPipeline:pipeline0/GstFPSDisplaySink:fpsdisplaysink0/GstXImageSink:ximagesink0: sync = true
    Got context from element 'vaapipostproc1': gst.vaapi.Display=context, gst.vaapi.Display=(GstVaapiDisplay)"\(GstVaapiDisplayGLX\)\ vaapidisplayglx0", gst.vaapi.Display.GObject=(GstObject)"\(GstVaapiDisplayGLX\)\ vaapidisplayglx0";
    Progress: (open) Opening Stream
    Pipeline is PREROLLED ...
    Prerolled, waiting for progress to finish...
    Progress: (connect) Connecting to rtsp://localhost:8554/camera_0
    Progress: (open) Retrieving server options
    Progress: (open) Retrieving media info
    Progress: (request) SETUP stream 0
    ```

    pipeline<time>_gst.log
    ```
    14.58
    14.58
    15.47
    15.47
    15.10
    15.10
    14.60
    14.60
    14.88
    14.88
    ```

    r<time>_gst.jsonl
    ```
    {"resolution":{"height":1080,"width":1920},"timestamp":1}
    {"objects":[{"detection":{"bounding_box":{"x_max":1.0,"x_min":0.7868695002029238,"y_max":0.8493015899134377,"y_min":0.4422388975124676},"confidence":0.7139435410499573,"label":"person","label_id":0},"h":440,"region_id":486,"roi_type":"person","w":409,"x":1511,"y":478}],"resolution":{"height":1080,"width":1920},"timestamp":66661013}
    {"objects":[{"detection":{"bounding_box":{"x_max":1.0,"x_min":0.6974737628926411,"y_max":0.8381138710318847,"y_min":0.44749696271196093},"confidence":0.7188630104064941,"label":"person","label_id":0},"h":422,"region_id":576,"roi_type":"person","w":581,"x":1339,"y":483}],"resolution":{"height":1080,"width":1920},"timestamp":133305076}
    ```

8. Stop the demo using docker compose down
```bash
make down
```

## [Proceed to Advanced Settings](advanced.md)

## [Pipeline Performance Tools](performance.md)