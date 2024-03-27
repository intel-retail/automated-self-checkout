#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

FROM golang:1.20.9-alpine3.18@sha256:174802dbb3172f847f129d75e3cd3f7fe8ef6895a0b1c830f0fc855a4aaf585c AS builder
RUN apk update && \
    apk add make autoconf libtool protobuf-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.31.0
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0
# Compile API
RUN wget https://raw.githubusercontent.com/openvinotoolkit/model_server/main/src/kfserving_api/grpc_predict_v2.proto
RUN echo 'option go_package = "./grpc-client";' >> grpc_predict_v2.proto
RUN protoc --go_out="./" --go-grpc_out="./" ./grpc_predict_v2.proto

COPY . .
RUN go mod tidy && make build-binary

FROM scratch as bin
COPY --from=builder /app/profile-launcher /