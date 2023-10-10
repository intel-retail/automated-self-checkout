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

CONTAINER_NAME=grpc_python"$cid_count"

rmDocker="--rm"

if [ -n "$DEBUG" ]
then
    rmDocker=
fi

docker run --network host $rmDocker \
    -e CONTAINER_NAME="$CONTAINER_NAME" \
    --name "$CONTAINER_NAME" \
    -v "$RUN_PATH"/results:/tmp/results \
    grpc_python:dev \
    python3 ./grpc_python.py --input_src "$inputsrc" --grpc_address 127.0.0.1 --grpc_port "$GRPC_PORT" --model_name "$DETECTION_MODEL_NAME" \
2>&1  | tee >"$RUN_PATH"/results/r$cid_count.jsonl >(stdbuf -oL sed -n -e 's/^.*fps: //p' | stdbuf -oL cut -d , -f 1 > "$RUN_PATH"/results/pipeline$cid_count.log)
