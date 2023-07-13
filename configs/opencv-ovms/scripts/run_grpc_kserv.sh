#!/bin/bash

# https://github.com/openvinotoolkit/model_server/tree/main/client/python/kserve-api/samples
GRPC_PORT="${GRPC_PORT:=9000}"

while :; do
    case $1 in
    --model_name)
        if [ "$2" ]; then
            DETECTION_MODEL_NAME=$2
            shift
        else
            error 'ERROR: "--model_name" requires an argument'
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




echo "running grpcpython with GRPC_PORT=$GRPC_PORT, DETECTION_MODEL_NAME:$DETECTION_MODEL_NAME"

# /scripts is mounted during the docker run 
# python3 /scripts/grpc_infer_binary_maskrcnn-omz.py --images_list /images/inputimages.txt --grpc_address 127.0.0.1 --grpc_port $GRPC_PORT --input_name image  --batchsize $BATCH_SIZE --model_name  instance-segmentation-security-1040 2>&1
# python3 /scripts/grpc_infer_binary_bit.py --images_list /images/inputimages.txt --grpc_address 127.0.0.1 --grpc_port $GRPC_PORT --input_name input_1  --batchsize $BATCH_SIZE --model_name  bit_64
if [ ! -z "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	python3 /scripts/grpc_python.py --input_src $inputsrc --grpc_address 127.0.0.1 --grpc_port $GRPC_PORT --model_name  "$DETECTION_MODEL_NAME"
else
	python3 /scripts/grpc_python.py --input_src $inputsrc --grpc_address 127.0.0.1 --grpc_port $GRPC_PORT --model_name  "$DETECTION_MODEL_NAME" 2>&1  | tee >/tmp/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
fi

