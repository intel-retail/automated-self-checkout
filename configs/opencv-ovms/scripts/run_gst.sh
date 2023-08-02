#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "Run gst pipeline"
rmDocker=--rm
if [ ! -z "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=""
fi

echo $rmDocker
TAG=sco-soc:2.0
pipeline="yolov5s.sh"

echo $PLATFORM

bash_cmd="/home/pipeline-server/framework-pipelines/$PLATFORM/$pipeline"
if [ "$STREAM_DENSITY_MODE" == 1 ]; then
	echo "Starting Stream Density"
	bash_cmd="./stream_density_framework-pipelines.sh framework-pipelines/$PLATFORM/$pipeline"
	stream_density_mount="-v $RUN_PATH/configs/dlstreamer/framework-pipelines/stream_density.sh:/home/pipeline-server/stream_density_framework-pipelines.sh"
	stream_density_params="-e STREAM_DENSITY_FPS=$STREAM_DENSITY_FPS -e STREAM_DENSITY_INCREMENTS=$STREAM_DENSITY_INCREMENTS -e COMPLETE_INIT_DURATION=$COMPLETE_INIT_DURATION"
	echo "DEBUG: $stream_density_params"
fi

if grep -q "rtsp" <<< "$inputsrc"; then
	# rtsp
	inputsrc=$inputsrc" ! rtph264depay "
fi

docker run --network host $cameras $TARGET_USB_DEVICE $TARGET_GPU_DEVICE --user root --ipc=host --name automated-self-checkout$cid_count -e RENDER_MODE=$RENDER_MODE $stream_density_mount -e INPUTSRC_TYPE=$INPUTSRC_TYPE -e DISPLAY=$DISPLAY -e cl_cache_dir=/home/pipeline-server/.cl-cache -v $cl_cache_dir:/home/pipeline-server/.cl-cache -v /tmp/.X11-unix:/tmp/.X11-unix -v $RUN_PATH/sample-media/:/home/pipeline-server/vids -v $RUN_PATH/configs/dlstreamer/pipelines:/home/pipeline-server/pipelines -v $RUN_PATH/configs/dlstreamer/extensions:/home/pipeline-server/extensions -v $RUN_PATH/results:/tmp/results -v $RUN_PATH/configs/dlstreamer/models/2022:/home/pipeline-server/models -v $RUN_PATH/configs/dlstreamer/framework-pipelines:/home/pipeline-server/framework-pipelines -w /home/pipeline-server -e BARCODE_RECLASSIFY_INTERVAL=$BARCODE_INTERVAL -e OCR_RECLASSIFY_INTERVAL=$OCR_INTERVAL -e OCR_DEVICE=$OCR_DEVICE -e LOG_LEVEL=$LOG_LEVEL -e GST_DEBUG=$GST_DEBUG -e decode_type="$decode_type" -e pre_process="$pre_process" -e LOW_POWER="$LOW_POWER" -e cid_count=$cid_count -e inputsrc="$inputsrc" $RUN_MODE $stream_density_params -e CPU_ONLY="$CPU_ONLY" -e AUTO_SCALE_FLEX_140="$AUTO_SCALE_FLEX_140" $TAG bash -c "bash $bash_cmd"
