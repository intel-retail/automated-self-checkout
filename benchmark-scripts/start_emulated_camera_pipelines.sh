#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

#to control number of object detected
INPUT_CAMERA=$1
#to control number of instance for pipeline-server
PIPELINE_NUMBER=$2
MODEL=yolov5s
STARTING_PORT=8080

# starting emulated cameras locally
./camera-simulator.sh
sleep 1

pipeline='
{
    "source": {
        "uri": "rtsp://127.0.0.1:8554/mycam",
        "type": "uri"
    },
    "destination": {
        "metadata": {
          "type": "file",
          "path": "/tmp/results/r.jsonl",
          "format":"json-lines"
        },
        "frame": {
          "type": "rtsp",
          "sync-with-source": false,
          "path": "mycam"
        }
    },
    "parameters": {
      "classification": {
        "device": "CPU"
      },
      "detection": {
        "device": "CPU"
       }
    }
}'

pipelineFile=$MODEL"_tracking_mixed_cpu_full"
echo $pipelineFile
PORT=$STARTING_PORT
echo "Performing mixed tracking with OD-interval=1, OC-interval=1, OCR-interval=3, Barcode-interval=3 "
for i in $( seq 0 $(($PIPELINE_NUMBER - 1)) )
do
	if [ $i != 0 ]; then
		PORT=$(($PORT + 1))
	fi
	pipeline_num=$((i + 1))
	declare pipelineName="pipeline"$pipeline_num
	pipelineName=$(echo $pipeline | sed "s/mycam/$INPUT_CAMERA/g")
	pipelineName=${pipelineName/r.json/r$i.json}
	echo $pipelineName
	curl -H 'Content-Type: application/json' http://127.0.0.1:$PORT/pipelines/xeon/$pipelineFile --data @- <<END;
	$pipelineName
END
done
