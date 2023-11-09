#!/bin/sh
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

echo "Running go unit tests..."

go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.31.0
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0

# make sure we have fresh file every time, delete it just in case
rm grpc_predict_v2.proto || true
# Compile grpc APIs
wget https://raw.githubusercontent.com/openvinotoolkit/model_server/main/src/kfserving_api/grpc_predict_v2.proto
echo 'option go_package = "./grpc-client";' >> grpc_predict_v2.proto
protoc --go_out="./" --go-grpc_out="./" ./grpc_predict_v2.proto

go mod tidy
go test -cover -count=1 ./...  || true

# cleanup
rm grpc_predict_v2.proto || true
rm -rf ./grpc-client/ || true
