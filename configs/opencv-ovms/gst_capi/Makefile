# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build

OVMS_CPP_DOCKER_IMAGE ?= openvino/model_server
OVMS_CPP_IMAGE_TAG ?= latest

build: build-ovms-server-22.04
	# Build CAPI docker image
	docker build $(NO_CACHE_OPTION) -f Dockerfile.ovms-capi-gst ../ \
		--build-arg http_proxy=$(HTTP_PROXY) \
		--build-arg https_proxy="$(HTTPS_PROXY)" \
		--build-arg no_proxy=$(NO_PROXY) \
		--build-arg BASE_IMAGE=ubuntu:22.04 \
		--progress=plain \
		-t $(OVMS_CPP_DOCKER_IMAGE)-capi-gst-ovms:$(OVMS_CPP_IMAGE_TAG)

build-ovms-server-22.04:
	@echo "Building for OVMS Server Ubuntu 22.04 (Recommended) HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY}"
	# Pull docker images for grpc/kserv distributed architecture
	# Ubuntu 22.04 support with CPU/iGPU/dGPU 
	docker pull openvino/model_server:2023.0-gpu