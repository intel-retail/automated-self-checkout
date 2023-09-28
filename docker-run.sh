#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

#!/bin/bash

VOLUME="-v `pwd`/results:/tmp/results -v `pwd`/configs/opencv-ovms/models/2022:/home/pipeline-server/models -v `pwd`/configs/opencv-ovms/models/2022:/models" 
ENVIRONMENT=""
DEVICE=CPU

while :; do
    case $1 in
    --device)
        if [ "$2" ]; then
            if [ $2 == "CPU" ]; then
                DEVICE=$2
                shift
            elif [ $2 == "MULTI:GPU,CPU" ]; then
                DEVICE=$2
                TARGET_GPU_DEVICE="--privileged"
                shift
            elif grep -q "GPU" <<< "$2"; then			
                DEVICE="GPU"
                arrgpu=(${2//./ })
                TARGET_GPU_NUMBER=${arrgpu[1]}
                if [ -z "$TARGET_GPU_NUMBER" ]; then
                    TARGET_GPU_DEVICE="--privileged"
                else
                    TARGET_GPU_ID=$((128+$TARGET_GPU_NUMBER))
                    TARGET_GPU_DEVICE="--device=/dev/dri/renderD"$TARGET_GPU_ID
                fi
                shift	
            else
                error 'ERROR: "--device" requires an argument CPU|GPU|MULTI'
            fi
        else
                echo 'DEBUG: "--device" no device set using default CPU'
        fi	    
        ;;
    --docker_image)
        if [ "$2" ]; then
            DOCKER_IMAGE=$2
            shift
        else
            error 'ERROR: "--docker_image" requires an argument'
        fi
        ;;
	--input_src)
	    if [ "$2" ]; then
            INPUT_SRC=$2
            shift
        else
            echo 'DEBUG: "--input_src" not set'
        fi
        ;;
	--render_mode)
		    RENDER_MODE=1
        ;;
	--volume)
	    if [ "$2" ]; then
            VOLUME+=" -v $2"
            shift
        fi
        ;;
	--environment)
	    if [ "$2" ]; then
            ENVIRONMENT+=" -e $2"
            shift
        fi
        ;;
	--env_file)
	    if [ "$2" ]; then
            ENV_FILE="--env-file $2"
            shift
        else
            echo 'no env file set using default env'
        fi
        ;;
	--command)
	    if [ "$2" ]; then
            COMMAND="$2"
            shift
        else
            echo 'no command set using default command'
        fi
        ;;
    -?*)
        error "ERROR: Unknown option $1"
        ;;
    ?*)
        error "ERROR: Unknown option $1"
        ;;
    *)
        break
        ;;
    esac
    shift
done

# Increment container id count
cids=$(docker ps  --filter="name=automated-self-checkout" -q -a)
cid_count=`echo "$cids" | wc -w`

# Set RENDER_MODE=1 for demo purposes only
RUN_MODE="-itd"
if [ "$RENDER_MODE" == 1 ]
then
	RUN_MODE="-it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix"
fi

# Mount the USB if using a usb camera
TARGET_USB_DEVICE=""
if [[ "$INPUT_SRC" == *"/dev/vid"* ]]
then
	TARGET_USB_DEVICE="--device=$INPUT_SRC"
fi

docker run --network host --user root --ipc=host \
$TARGET_USB_DEVICE \
$TARGET_GPU_DEVICE \
--name automated-self-checkout$cid_count \
-e RENDER_MODE=$RENDER_MODE \
$RUN_MODE \
$VOLUME \
$ENV_FILE \
$ENVIRONMENT \
-e cid_count=$cid_count \
-e INPUT_SRC="$INPUT_SRC" \
-e DEVICE=$DEVICE \
$DOCKER_IMAGE \
$COMMAND