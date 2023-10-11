#!/bin/bash

# https://github.com/openvinotoolkit/model_server/tree/main/client/python/kserve-api/samples
GRPC_PORT="${GRPC_PORT:=9000}"
cid_count="${cid_count:=0}"

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

# Run the grpc python client
python3 ./grpc_python.py --input_src "$INPUTSRC" --grpc_address 127.0.0.1 --grpc_port "$GRPC_PORT" --model_name "$DETECTION_MODEL_NAME" \
2>&1  | tee >/tmp/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > /tmp/results/pipeline$cid_count.log)
