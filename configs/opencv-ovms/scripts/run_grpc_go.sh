#!/bin/bash

GRPC_PORT="${GRPC_PORT:=9000}"

echo "running grpc_go with GRPC_PORT=$GRPC_PORT"

# /scripts is mounted during the docker run 

rmDocker=--rm
if [ ! -z "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=""
fi

echo $rmDocker
docker run --network host --privileged $rmDocker -v $RUN_PATH/results:/tmp/results --name dev -p 8080:8080 grpc:dev bash -c './grpc-go -i $inputsrc -u 127.0.0.1:$GRPC_PORT -o /tmp/results'