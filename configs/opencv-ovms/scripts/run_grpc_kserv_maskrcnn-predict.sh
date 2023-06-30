#!/bin/bash

# https://github.com/openvinotoolkit/model_server/tree/main/client/python/kserve-api/samples
GRPC_PORT=9000
if [ ! -z "$1" ]; then
    GRPC_PORT=$1
fi

BATCH_SIZE=1
if [ ! -z "$2" ]; then
	BATCH_SIZE=$2
fi

# /scripts is mounted during the docker run 
python3 /scripts/grpc_infer_binary_maskrcnn-omz.py --images_list /images/inputimages.txt --grpc_address 127.0.0.1 --grpc_port $GRPC_PORT --input_name image  --batchsize $BATCH_SIZE --model_name  instance-segmentation-security-1040 2>&1 | stdbuf -oL cat > /tmp/results/maskrcnn.log
