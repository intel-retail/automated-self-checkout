# automated/static inputs:
- name
- network
- user
- ipc=host

# required user inputs:

- inputsrc 
 - inputsrc_type (remove) - need to add logic into the gst scripts to format the inputsrc
-device - need to determine devices such as the GPU (GST_VAAPI_DRM_DEVICE=/dev/dri/renderD128 || 129), USB device, RealSense. $TARGET_USB_DEVICE $TARGET_GPU_DEVICE
  - should we use this like platform but use CPU|GPU.x|mixed as the inputs?
  - do we create a new one specifically for usb or do we put logic to auto mount the usb devices if inputsrc is usb?

# optional:

- render mode + -e DISPLAY=$DISPLAY + -v /tmp/.X11-unix:/tmp/.X11-unix 

# needed?:

  -e cl_cache_dir=/home/pipeline-server/.cl-cache 
  -v $cl_cache_dir:/home/pipeline-server/.cl-cache 

# volumes:

  - media files if using (only required for files)
   - pipelines/scripts - remove this and build it into the docker image, use env file to modify pipeline
   - extensions same as pipelines/scripts
  - results will come from benchmark -> docker-run
  - models will also come from benchmark -> docker-run. These could be local or remote
   - framework-pipelines same as pipelines
   - cmd_client - want to remove and replace with simple env config + dockerfiles

# environment:

  - make these configurable in a env-language-pipeline file
  - load these through the benchmark -> docker-run script

stream_density: need to rework logic to make this run on all pipelines. just need a common output for this to work

# new params:

 - config_file
  - docker_image
  - list of environment vars or an env file
    - do we need a program to read in the non env config (docker-image) and rewrite env that are overridden? NO
    - We can use the -e to override any environment variables in the docker container. Only tricky part is setting them in the run / benchmark script


# dlstreamer

./docker-run.sh --device CPU --docker_image gst:dev --input_src rtsp://127.0.0.1:8554/camera_0 --env_file configs/dlstreamer/framework-pipelines/yolov5_pipeline/yolov5-cpu.env

docker run --network host --user root --ipc=host --privileged --name automated-self-checkout2 -e RENDER_MODE= -it -v /home/intel/projects/automated-self-checkout/results:/tmp/results -v /home/intel/projects/automated-self-checkout/configs/models/2022:/home/pipeline-server/models --env-file configs/dlstreamer/framework-pipelines/yolov5_pipeline/yolov5.env -e cid_count=2 -e INPUT_SRC=rtsp://127.0.0.1:8554/camera_0 -e DEVICE=CPU --entrypoint bash gst:dev

sh $GST_PIPELINE_LAUNCH

gst-launch-1.0 rtsp://127.0.0.1:8554/camera_0 ! rtph264depay ! vaapidecodebin ! gvadetect model-instance-id=odmodel name=detection model=models/yolov5s/1/FP16-INT8/yolov5s.xml model-proc=models/yolov5s/1/yolov5s.json threshold=.5 device=GPU pre-process-backend=vaapi-surface-sharing pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1 ! gvametaaggregate name=aggregate ! gvametaconvert name=metaconvert add-empty-results=true ! gvametapublish name=destination file-format=2 file-path=/tmp/results/r2.jsonl ! fpsdisplaysink video-sink=fakesink sync=true --verbose 


# ovms server

./docker-run.sh --docker_image openvino/model_server:2023.1-gpu --command '--config_path /home/pipeline-server/models/config.json --port 9000'

# ovms client with cmd client segmentation

./docker-run.sh --device CPU --docker_image grpc_python:dev --input_src rtsp://127.0.0.1:8554/camera_0 --env_file configs/opencv-ovms/cmd_client/res/grpc_python/grpc_python.env

# ovms client with cmd client bit

./docker-run.sh --device CPU --docker_image grpc_python:dev --input_src rtsp://127.0.0.1:8554/camera_0 --env_file configs/opencv-ovms/scripts/grpc_python_cmd_client.env --environment PIPELINE_PROFILE=grpc_python_bit

# ovms client python direct

./docker-run.sh --device CPU --docker_image grpc_python:dev --input_src rtsp://127.0.0.1:8554/camera_0 --env_file configs/opencv-ovms/scripts/grpc_python.env

# ovms client python direct with params (obsolete)

./docker-run.sh --device CPU --docker_image grpc_python:dev --input_src rtsp://127.0.0.1:8554/camera_0 --environment PIPELINE_PROFILE=grpc_python --env_file configs/opencv-ovms/scripts/grpc_python.env --command "python3 /scripts/grpc_python.py --input_src rtsp://127.0.0.1:8554/camera_0 --grpc_address 127.0.0.1 --grpc_port 9000 --model_name instance-segmentation-security-1040"

# benchmark
# dlstreamer yolo cpu

sudo ./benchmark.sh --pipelines 2 --logdir benchmark-test/dl-yolo-cpu --init_duration 15 --duration 30 --device CPU --docker_image gst:dev --input_src rtsp://127.0.0.1:8554/camera_0 --env_file configs/dlstreamer/framework-pipelines/yolov5_pipeline/yolov5.env
# dlstreamer yolo gpu

sudo ./benchmark.sh --pipelines 2 --logdir benchmark-test/dl-yolo-gpu --init_duration 15 --duration 30 --device GPU --docker_image gst:dev --input_src rtsp://127.0.0.1:8554/camera_0 --env_file configs/dlstreamer/framework-pipelines/yolov5_pipeline/yolov5-gpu.env


# OVMS server first

./docker-run.sh --docker_image docker.io/openvino/model_server-gpu:latest --command '--config_path /home/pipeline-server/models/config.json --port 9000'

sudo ./benchmark.sh --pipelines 2 --logdir benchmark-test/python-rcnn --init_duration 15 --duration 30 --device CPU --docker_image grpc_python:dev --input_src rtsp://127.0.0.1:8554/camera_0 --env_file configs/opencv-ovms/scripts/grpc_python.env