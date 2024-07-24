  * Prepare models

      Use the model downloader [available here](https://github.com/dlstreamer/pipeline-server/tree/main/tools/model_downloader) to download new models. Point `MODEL_DIR` to the directory containing the new models. The following section assumes that the new models are available under `$(pwd)/models`.
   ```bash
    $ export MODEL_DIR=$(pwd)/models
   ```
object_detection/yolov5s/yolov5s.json
object_detection/yolov5s/FP32

 * Prepare pipelines

     Use [these docs](https://github.com/dlstreamer/pipeline-server/blob/main/docs/defining_pipelines.md) to get started with defining new pipelines. Once the new pipelines have been defined, point `PIPELINE_DIR` to the directory containing the new pipelines. The following section assumes that the new pipelines are available under `$(pwd)/pipelines`.
    ```bash
    $ export PIPELINE_DIR=$(pwd)/pipelines
   ```
 
 * Run the image with new models and pipelines mounted into the container
 ```bash
   $ docker run -itd \
      --privileged \
      --device=/dev:/dev \
      --device-cgroup-rule='c 189:* rmw' \
      --device-cgroup-rule='c 209:* rmw' \
      --group-add 109 \
      --name evam \
      -p 8080:8080 \
      -p 8554:8554 \
      -e ENABLE_RTSP=true \
      -e RTSP_PORT=8554 \
      -e ENABLE_WEBRTC=true \
      -e WEBRTC_SIGNALING_SERVER=ws://localhost:8443 \
      -e RUN_MODE=EVA \
      -e DETECTION_DEVICE=CPU \
      -e CLASSIFICATION_DEVICE=CPU \
      -v ./models:/home/pipeline-server/models \
      -v ./src/pipelines:/home/pipeline-server/pipelines \
      dlstreamer:dev
 ```
## Starting pipelines
 * We can trigger pipelines using the *pipeline server's* REST endpoints, here is an example cURL command, the output is available as a RTSP stream at *rtsp://<host ip>/pipeline-server*
 ```bash
    $ curl localhost:8080/pipelines/object_detection/yolov5 -X POST -H \
      'Content-Type: application/json' -d \
      '{
         "source": {
            "uri": "rtsp://192.168.1.141:8555/camera_0",
            "type": "uri"
         },
         "destination": {
            "metadata": {
               "type": "file",
               "path": "/tmp/results.jsonl",
               "format": "json-lines"
            },
            "frame": {
               "type": "rtsp",
               "path": "pipeline-server"
            }
         },
         "parameters": {
            "detection-device": "CPU",
            "network": "FP16-INT8"
         }
      }'
 ```