#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

FROM golang:1.20.9-alpine3.18 AS builder
RUN apk update && apk add make
WORKDIR /app
COPY . .
RUN make build-binary

FROM scratch as bin
COPY --from=builder /app/profile-launcher /