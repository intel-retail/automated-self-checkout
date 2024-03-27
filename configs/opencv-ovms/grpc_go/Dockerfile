#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

FROM gocv/opencv:4.7.0@sha256:e7d8cc66c42717323587354d842903dd8372afa74aa6b82631bcf8f17a398ddf AS builder

RUN apt-get update && \
    apt-get -y install git unzip build-essential autoconf libtool protobuf-compiler libprotobuf-dev --fix-missing && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /app
WORKDIR /app


RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.31.0
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0

# Compile API
RUN wget https://raw.githubusercontent.com/openvinotoolkit/model_server/main/src/kfserving_api/grpc_predict_v2.proto
RUN echo 'option go_package = "./grpc-client";' >> grpc_predict_v2.proto
RUN protoc --go_out="./" --go-grpc_out="./" ./grpc_predict_v2.proto

COPY . .

RUN go mod tidy
RUN go build -o grpc-go && chmod +x entrypoint.sh
