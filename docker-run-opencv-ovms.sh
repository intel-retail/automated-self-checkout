#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

SERVER_CONTAINER_NAME="model-server"
CLIENT_CONTAINER_NAME_PREFIX="ovms-client"
# clean up exited containers
docker rm $(docker ps -a -f name=$SERVER_CONTAINER_NAME -f status=exited -q)
docker rm $(docker ps -a -f name=$CLIENT_CONTAINER_NAME_PREFIX -f status=exited -q)

export GST_DEBUG=0

source benchmark-scripts/get-gpu-info.sh

if [ -z "$PLATFORM" ] || [ -z "$INPUTSRC" ]
then
	source get-options.sh "$@"
fi

cl_cache_dir=`pwd`/.cl-cache
echo "CLCACHE: $cl_cache_dir"


# TODO: override tag for other images and workloads
#todo: update this section
if [ $HAS_FLEX_140 == 1 ] || [ $HAS_FLEX_170 == 1 ] || [ $HAS_ARC == 1 ] 
then
	if [ $OCR_DISABLED == 0 ]
	then
        	echo "OCR device defaulting to dGPU"
        	OCR_DEVICE=GPU
	fi
	if [ $PLATFORM == "dgpu" ]
	then
		echo "Arc/Flex device driver stack"
		SERVER_TAG=docker.io/openvino/model_server-gpu:latest
	        CLIENT_TAG=ovms-client:latest
	else
		SERVER_TAG=docker.io/openvino/model_server-gpu:latest
	        CLIENT_TAG=ovms-client:latest
		echo "SOC (CPU, iGPU, and Xeon SP) device driver stack"
	fi

	if [ $HAS_ARC == 1 ]; then
		PLATFORM="arc"
	fi

else
	echo "SOC (CPU, iGPU, and Xeon SP) device driver stack"
	SERVER_TAG=docker.io/openvino/model_server-gpu:latest
	CLIENT_TAG=ovms-client:latest
fi

if [ ! -z "$CONTAINER_IMAGE_OVERRIDE" ]
then
	echo "Using container image override $CONTAINER_IMAGE_OVERRIDE"
	TAG=$CONTAINER_IMAGE_OVERRIDE
fi

cids=$(docker ps  --filter="name=$CLIENT_CONTAINER_NAME_PREFIX" -q -a)
cid_count=`echo "$cids" | wc -w`
CLIENT_CONTAINER_NAME=$CLIENT_CONTAINER_NAME_PREFIX$(($cid_count))
SERVER_CONTAINER_NAME=$SERVER_CONTAINER_NAME$(($cid_count))

#echo "barcode_disabled: $BARCODE_DISABLED, barcode_interval: $BARCODE_INTERVAL, ocr_interval: $OCR_INTERVAL, ocr_device: $OCR_DEVICE, ocr_disabled=$OCR_DISABLED, class_disabled=$CLASSIFICATION_DIABLED"
pre_process=""
if grep -q "rtsp" <<< "$INPUTSRC"; then
	# rtsp
	# todo pass depay info
	inputsrc=$INPUTSRC
	INPUTSRC_TYPE="RTSP"
	pre_process="pre-process-backend=vaapi-surface-sharing -e pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1"


elif grep -q "file" <<< "$INPUTSRC"; then
	# filesrc	
	arrfilesrc=(${INPUTSRC//:/ })
	# use vids since container maps a volume to this location based on sample-media folder
	# TODO: need to pass demux/codec info
	inputsrc="filesrc location=vids/"${arrfilesrc[1]}" ! qtdemux ! h264parse "
	INPUTSRC_TYPE="FILE"
	decode_type="vaapidecodebin"
	pre_process="pre-process-backend=vaapi-surface-sharing -e pre-process-config=VAAPI_FAST_SCALE_LOAD_FACTOR=1"

elif grep -q "video" <<< "$INPUTSRC"; then
	# v4l2src /dev/video*
	# TODO need to pass stream info
	inputsrc="v4l2src device="$INPUTSRC
	INPUTSRC_TYPE="USB"
	TARGET_USB_DEVICE="--device=$INPUTSRC"
	decode_type="videoconvert ! video/x-raw,format=BGR"
	pre_process=""

else
	# rs-serial realsenssrc
	# TODO need to pass depthalign info
	inputsrc="realsensesrc cam-serial-number="$INPUTSRC" stream-type=0 align=0 imu_on=false"
    # add realsense color related properties if any
	if [ "$COLOR_WIDTH" != 0 ]; then
		inputsrc=$inputsrc" color-width="$COLOR_WIDTH
	fi
	if [ "$COLOR_HEIGHT" != 0 ]; then
		inputsrc=$inputsrc" color-height="$COLOR_HEIGHT
	fi
	if [ "$COLOR_FRAMERATE" != 0 ]; then
		inputsrc=$inputsrc" color-framerate="$COLOR_FRAMERATE
	fi
	INPUTSRC_TYPE="REALSENSE"
	decode_type="decodebin ! videoconvert ! video/x-raw,format=BGR"
	pre_process=""
	cameras=`ls /dev/vid* | while read line; do echo "--device=$line"; done`
	TARGET_GPU_DEVICE=$TARGET_GPU_DEVICE" "$cameras	
fi

#todo: this will need to be updated to how we are supporting these configs
# TODO: the different combination of pipelines should put into another pipeline script that can be configured in configuraiton.yaml so that it can be run in more unified way

#pipeline script is configured from configuration.yaml in opencv-ovms/cmd_client/res folder

# Set RENDER_MODE=1 for demo purposes only
RUN_MODE="-itd"
if [ "$RENDER_MODE" == 1 ]
then
	xhost +local:docker
	#RUN_MODE="-it"
fi

if [ "$STREAM_DENSITY_MODE" == 1 ]; then
	echo "Starting Stream Density"
	stream_density_mount="-v `pwd`/configs/dlstreamer/framework-pipelines/stream_density.sh:/home/pipeline-server/stream_density_framework-pipelines.sh"
	grpc_go_mount="-v `pwd`/configs/opencv-ovms/grpc_go/stream_density_run.sh:/app/stream_density_run.sh -v `pwd`/configs/opencv-ovms/grpc_go/entrypoint.sh:/app/entrypoint.sh"
	stream_density_params="-e STREAM_DENSITY_FPS=$STREAM_DENSITY_FPS -e STREAM_DENSITY_INCREMENTS=$STREAM_DENSITY_INCREMENTS -e COMPLETE_INIT_DURATION=$COMPLETE_INIT_DURATION"
	echo "DEBUG: $stream_density_params"
fi

#echo "DEBUG: $TARGET_GPU_DEVICE $PLATFORM $HAS_FLEX_140"
if [ "$PLATFORM" == "dgpu" ] && [ $HAS_FLEX_140 == 1 ]
then
	if [ "$STREAM_DENSITY_MODE" == 1 ]; then
		# override logic in workload script so stream density can manage it
		AUTO_SCALE_FLEX_140=2
	else
		# allow workload to manage autoscaling
		AUTO_SCALE_FLEX_140=1
	fi
fi

# make sure models are downloaded or existing:
./download_models/getModels.sh --workload opencv-ovms

# make sure sample image is downloaded or existing:
./configs/opencv-ovms/scripts/image_download.sh

# Set GRPC port based on number of servers and clients
GRPC_PORT=$(( 9000 + $cid_count ))

# Modify the config file if the device env is set
# devices supported CPU, GPU, GPU.x, AUTO, MULTI:GPU,CPU
if [ ! -z "$DEVICE" ]; then
	echo "Updating config with device environment variable"
	docker run --rm -v `pwd`/configs/opencv-ovms/models/2022:/configFiles -e DEVICE=$DEVICE update_config:dev
fi

#start the server
echo "starting server"
docker run --network host $cameras $TARGET_USB_DEVICE $TARGET_GPU_DEVICE --user root --ipc=host --name $SERVER_CONTAINER_NAME \
-e RENDER_MODE=$RENDER_MODE $stream_density_mount \
-e INPUTSRC_TYPE=$INPUTSRC_TYPE -e DISPLAY=$DISPLAY \
-e cl_cache_dir=/home/pipeline-server/.cl-cache \
-v $cl_cache_dir:/home/pipeline-server/.cl-cache \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v `pwd`/sample-media/:/home/pipeline-server/vids \
-v `pwd`/configs/pipelines:/home/pipeline-server/pipelines \
-v `pwd`/configs/extensions:/home/pipeline-server/extensions \
-v `pwd`/results:/tmp/results \
-v `pwd`/configs/opencv-ovms/models/2022:/models \
-v `pwd`/configs/framework-pipelines:/home/pipeline-server/framework-pipelines \
-e BARCODE_RECLASSIFY_INTERVAL=$BARCODE_INTERVAL \
-e OCR_RECLASSIFY_INTERVAL=$OCR_INTERVAL \
-e OCR_DEVICE=$OCR_DEVICE \
-e LOG_LEVEL=$LOG_LEVEL \
-e decode_type="$decode_type" \
-e pre_process="$pre_process" \
-e LOW_POWER="$LOW_POWER" \
-e cid_count=$cid_count \
-e inputsrc="$inputsrc" $RUN_MODE $stream_density_params \
-e CPU_ONLY="$CPU_ONLY" \
-e AUTO_SCALE_FLEX_140="$AUTO_SCALE_FLEX_140" $SERVER_TAG --config_path /models/config.json --port $GRPC_PORT
echo "Let server settle a bit"
sleep 10

# PIPELINE_PROFILE is the environment variable to choose which type of pipelines to run with
# eg. grpc_python, grpc_cgo_binding, ... etc
# one example to run with this pipeline profile on the command line is like:
# PIPELINE_PROFILE="grpc_python" sudo -E ./docker-run.sh --workload opencv-ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
PIPELINE_PROFILE="${PIPELINE_PROFILE:=grpc_python}"
echo "starting client(s) with pipeline profile: $PIPELINE_PROFILE ..."
docker run --network host $cameras $TARGET_USB_DEVICE $TARGET_GPU_DEVICE --user root --privileged --ipc=host --name $CLIENT_CONTAINER_NAME \
-e MQTT="$MQTT" \
-e RENDER_MODE=$RENDER_MODE $stream_density_mount \
-e INPUTSRC_TYPE=$INPUTSRC_TYPE -e DISPLAY=$DISPLAY \
-e cl_cache_dir=/home/pipeline-server/.cl-cache \
-e RUN_PATH=`pwd` \
-v $cl_cache_dir:/home/pipeline-server/.cl-cache \
-v ~/.Xauthority:/home/dlstreamer/.Xauthority \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v `pwd`/sample-media/:/home/pipeline-server/vids \
-v `pwd`/configs/pipelines:/home/pipeline-server/pipelines \
-v `pwd`/configs/extensions:/home/pipeline-server/extensions \
-v `pwd`/results:/tmp/results \
-v `pwd`/configs/opencv-ovms/images:/images \
-v `pwd`/configs/opencv-ovms/scripts:/scripts \
-v `pwd`/configs/opencv-ovms/models/2022:/models \
-v `pwd`/configs/opencv-ovms/cmd_client/res:/model_server/client/cmd_client/res \
-v `pwd`/configs/framework-pipelines:/home/pipeline-server/framework-pipelines \
-v /var/run/docker.sock:/var/run/docker.sock \
$grpc_go_mount \
-e PLATFORM=$PLATFORM \
-e BARCODE_RECLASSIFY_INTERVAL=$BARCODE_INTERVAL \
-e OCR_RECLASSIFY_INTERVAL=$OCR_INTERVAL \
-e OCR_DEVICE=$OCR_DEVICE \
-e LOG_LEVEL=$LOG_LEVEL \
-e decode_type="$decode_type" \
-e pre_process="$pre_process" \
-e LOW_POWER="$LOW_POWER" \
-e cid_count=$cid_count \
-e STREAM_DENSITY_MODE=$STREAM_DENSITY_MODE \
-e inputsrc="$inputsrc" $RUN_MODE $stream_density_params \
-e CPU_ONLY="$CPU_ONLY" \
-e GRPC_PORT="$GRPC_PORT" \
-e PIPELINE_PROFILE="$PIPELINE_PROFILE" \
-e AUTO_SCALE_FLEX_140="$AUTO_SCALE_FLEX_140" $CLIENT_TAG ./ovms-client
