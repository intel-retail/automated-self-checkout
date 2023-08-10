# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build-all build-soc build-dgpu run-camera-simulator clean clean-simulator clean-ovms-client clean-grpc-go clean-model-server clean-ovms clean-all build-grpc-go clean-results

MKDOCS_IMAGE ?= asc-mkdocs

build-all: build-soc build-dgpu

build-soc:
	echo "Building for SOC (e.g. TGL/ADL/Xeon SP/etc) HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY}"
	docker build --no-cache --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t sco-soc:2.0 -f Dockerfile.soc .

build-dgpu:
	echo "Building for dgpu Arc/Flex HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY}"
	docker build --no-cache --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t sco-dgpu:2.0 -f Dockerfile.dgpu .

run-camera-simulator:
	./camera-simulator/camera-simulator.sh

clean:
	./clean-containers.sh automated-self-checkout

clean-simulator:
	./clean-containers.sh camera-simulator

build-ovms-client:
	echo "Building for OVMS Client HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY}"
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t ovms-client:latest -f Dockerfile.ovms-client .

build-ovms-server: get-server-code
	@echo "Building for OVMS Server HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY}"
	$(MAKE) -C model_server docker_build OV_USE_BINARY=0 BASE_OS=ubuntu OV_SOURCE_BRANCH=seg_and_bit_gpu_poc
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -f $(PWD)/configs/opencv-ovms/models/2022/Dockerfile.updateDevice -t update_config:dev $(PWD)/configs/opencv-ovms/models/2022/.

get-server-code:
	@if [ -d "./model_server" ]; then echo "clean up the existing model_server directory"; rm -rf ./model_server; fi
	echo "Getting model_server code"
	git clone https://github.com/gsilva2016/model_server 

clean-ovms-client: clean-grpc-go
	./clean-containers.sh ovms-client

clean-grpc-go:
	./clean-containers.sh dev

clean-model-server:
	./clean-containers.sh model-server

clean-ovms: clean-ovms-client clean-model-server

clean-all: clean clean-ovms clean-simulator clean-results

docs: clean-docs
	mkdocs build
	mkdocs serve -a localhost:8008

docs-builder-image:
	docker build \
		-f Dockerfile.docs \
		-t $(MKDOCS_IMAGE) \
		.

build-docs: docs-builder-image
	docker run --rm \
		-v $(PWD):/docs \
		-w /docs \
		$(MKDOCS_IMAGE) \
		build

serve-docs: docs-builder-image
	docker run --rm \
		-it \
		-p 8008:8000 \
		-v $(PWD):/docs \
		-w /docs \
		$(MKDOCS_IMAGE)

build-grpc-go: build-ovms-client
	cd configs/opencv-ovms/grpc_go && make build

build-python-apps: build-ovms-client 
	cd configs/opencv-ovms/instance_segmentation_demo/python && make build

clean-docs:
	rm -rf docs/

clean-results:
	sudo rm -rf results/*
