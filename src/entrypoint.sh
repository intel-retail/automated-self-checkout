#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

checkBatchSize() {
	if [ "$BATCH_SIZE" -lt 0 ]
	then
		echo "Invalid: BATCH_SIZE should be >= 0: $BATCH_SIZE"
		exit 1
	elif [ "$BATCH_SIZE" -gt 1024 ]
	then
		echo "Invalid: BATCH_SIZE should be <= 1024: $BATCH_SIZE"
		exit 1
	fi
	echo "Ok, BATCH_SIZE = $BATCH_SIZE"
}

cid_count="${cid_count:=0}"
cameras="${cameras:=}"
stream_density_mount="${stream_density_mount:=}"
stream_density_params="${stream_density_params:=}"
cl_cache_dir="${cl_cache_dir:=$HOME/.cl-cache}"

COLOR_WIDTH="${COLOR_WIDTH:=1920}"
COLOR_HEIGHT="${COLOR_HEIGHT:=1080}"
COLOR_FRAMERATE="${COLOR_FRAMERATE:=15}"
BATCH_SIZE="${BATCH_SIZE:=0}"
DECODE="${DECODE:="decodebin force-sw-decoders=1"}" #decodebin|vaapidecodebin
DEVICE="${DEVICE:="CPU"}" #GPU|CPU|MULTI:GPU,CPU

show_help() {
	echo "usage: \"--pipeline_script_choice\" requires an argument yolov5s.sh|yolov5s_effnetb0.sh|yolov5s_full.sh"
}

while :; do
    case $1 in
    --pipeline_script_choice)
        if [ "$2" ]; then
            PIPELINE_SCRIPT=$2
            shift
        else
            echo "ERROR on input value: $2"
			show_help
			exit
        fi
        ;;
    -?*)
        error "ERROR: Unknown option $1"
		show_help
		exit
        ;;
    ?*)
        error "ERROR: Unknown option $1"
		show_help
		exit
        ;;
    *)
        break
        ;;
    esac

    shift

done

if [ "$PIPELINE_SCRIPT" != "yolov5s.sh" ] && [ "$PIPELINE_SCRIPT" != "yolov5s_effnetb0.sh" ] && [ "$PIPELINE_SCRIPT" != "yolov5s_full.sh" ]
then
	echo "Error on your input: $PIPELINE_SCRIPT"
	show_help
	exit
fi

echo "Run gst pipeline profile $PIPELINE_SCRIPT"
cd /home/pipeline-server || exit

rmDocker=--rm
if [ -n "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=
fi

echo "OCR_RECLASSIFY_INTERVAL=$OCR_RECLASSIFY_INTERVAL  BARCODE_RECLASSIFY_INTERVAL=$BARCODE_RECLASSIFY_INTERVAL"

echo "$rmDocker"
bash_cmd="/home/pipeline-server/pipelines/$PIPELINE_SCRIPT"

inputsrc="$INPUTSRC"
if grep -q "rtsp" <<< "$INPUTSRC"; then
	# rtsp
	inputsrc=$INPUTSRC" ! rtph264depay "
elif grep -q "file" <<< "$INPUTSRC"; then
	arrfilesrc=(${INPUTSRC//:/ })
	# use vids since container maps a volume to this location based on sample-media folder
	inputsrc="filesrc location=vids/"${arrfilesrc[1]}" ! qtdemux ! h264parse "
elif grep -q "video" <<< "$INPUTSRC"; then
	inputsrc="v4l2src device="$INPUTSRC
	DECODE="$DECODE ! videoconvert ! video/x-raw,format=BGR"
	# when using realsense camera, the dgpu.0 not working
else
	# rs-serial realsenssrc
	inputsrc="realsensesrc cam-serial-number="$INPUTSRC" stream-type=0 align=0 imu_on=false"
	echo "----- in run_gst.sh COLOR_WIDTH=$COLOR_WIDTH, COLOR_HEIGHT=$COLOR_HEIGHT, COLOR_FRAMERATE=$COLOR_FRAMERATE"

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
	DECODE="$DECODE ! videoconvert ! video/x-raw,format=BGR"
	# when using realsense camera, the dgpu.0 not working
fi

# generate unique container id based on the date with the precision upto nano-seconds
cid=$(date +%Y%m%d%H%M%S%N)
echo "cid: $cid"

touch /tmp/results/r"$cid"_gst.jsonl
chown 1000:1000 /tmp/results/r"$cid"_gst.jsonl
touch /tmp/results/gst-launch_"$cid"_gst.log
chown 1000:1000 /tmp/results/gst-launch_"$cid"_gst.log
touch /tmp/results/pipeline"$cid"_gst.log
chown 1000:1000 /tmp/results/pipeline"$cid"_gst.log

cl_cache_dir="/home/pipeline-server/.cl-cache" \
DISPLAY="$DISPLAY" \
RESULT_DIR="/tmp/result" \
DECODE="$DECODE" \
DEVICE="$DEVICE" \
BATCH_SIZE="$BATCH_SIZE" \
PRE_PROCESS="$PRE_PROCESS" \
BARCODE_RECLASSIFY_INTERVAL="$BARCODE_INTERVAL" \
OCR_RECLASSIFY_INTERVAL="$OCR_INTERVAL" \
OCR_DEVICE="$OCR_DEVICE" \
LOG_LEVEL="$LOG_LEVEL" \
GST_DEBUG="$GST_DEBUG" \
cid="$cid" \
inputsrc="$inputsrc" \
OCR_RECLASSIFY_INTERVAL="$OCR_RECLASSIFY_INTERVAL" \
BARCODE_RECLASSIFY_INTERVAL="$BARCODE_RECLASSIFY_INTERVAL" \
"$bash_cmd"
