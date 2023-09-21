# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build-all build-soc build-dgpu build-grpc-python build-grpc-go build-profile-launcher build-python-apps build-telegraf
.PHONY: run-camera-simulator run-telegraf
.PHONY: clean-profile-launcher clean-grpc-go clean-segmentation clean-ovms-server clean-ovms clean-all clean-results clean-telegraf clean-models
.PHONY: clean clean-simulator clean-object-detection
.PHONY: list-profiles
.PHONY: unit-test-profile-launcher

MKDOCS_IMAGE ?= asc-mkdocs

build-all: build-soc build-dgpu

build-soc:
	echo "Building for SOC (e.g. TGL/ADL/Xeon SP/etc) HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY}"
	docker build --no-cache --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t sco-soc:2.0 -f Dockerfile.soc .

build-dgpu:
	echo "Building for dgpu Arc/Flex HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY}"
	docker build --no-cache --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t sco-dgpu:2.0 -f Dockerfile.dgpu .

build-telegraf:
	cd telegraf && $(MAKE) build

run-camera-simulator:
	./camera-simulator/camera-simulator.sh

run-telegraf:
	cd telegraf && $(MAKE) run

clean:
	./clean-containers.sh automated-self-checkout

clean-simulator:
	./clean-containers.sh camera-simulator

build-profile-launcher:
	@cd ./configs/opencv-ovms/cmd_client && $(MAKE) build
	@./create-symbolic-link.sh $(PWD)/configs/opencv-ovms/cmd_client/profile-launcher profile-launcher
	@./create-symbolic-link.sh $(PWD)/configs/opencv-ovms/scripts scripts
	@./create-symbolic-link.sh $(PWD)/configs/opencv-ovms/envs envs
	@./create-symbolic-link.sh $(PWD)/benchmark-scripts/stream_density.sh stream_density.sh

build-ovms-server:
	HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY} docker pull openvino/model_server:2023.1-gpu
	sudo docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -f configs/opencv-ovms/models/2022/Dockerfile.updateDevice -t update_config:dev configs/opencv-ovms/models/2022/.

clean-profile-launcher: clean-grpc-python clean-grpc-go clean-segmentation clean-object-detection
	@echo "containers launched by profile-launcher are cleaned up."
	@pkill profile-launcher || true

clean-grpc-python:
	./clean-containers.sh grpc_python

clean-grpc-go:
	./clean-containers.sh dev

clean-segmentation:
	./clean-containers.sh segmentation

clean-object-detection:
	./clean-containers.sh object-detection

clean-ovms-server:
	./clean-containers.sh ovms-server

clean-ovms: clean-profile-launcher clean-ovms-server

clean-telegraf: 
	./clean-containers.sh influxdb2
	./clean-containers.sh telegraf

clean-all: clean clean-ovms clean-simulator clean-results clean-telegraf

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
		-u $(shell id -u):$(shell id -g) \
		-v $(PWD):/docs \
		-w /docs \
		$(MKDOCS_IMAGE) \
		build

serve-docs: docs-builder-image
	docker run --rm \
		-it \
		-u $(shell id -u):$(shell id -g) \
		-p 8008:8000 \
		-v $(PWD):/docs \
		-w /docs \
		$(MKDOCS_IMAGE)

build-grpc-python: build-profile-launcher
	cd configs/opencv-ovms/grpc_python && $(MAKE) build

build-grpc-go: build-profile-launcher
	cd configs/opencv-ovms/grpc_go && make build

build-python-apps: build-profile-launcher
	cd configs/opencv-ovms/demos && make build	

clean-docs:
	rm -rf docs/

clean-results:
	sudo rm -rf results/*

list-profiles:
	@echo "Here is the list of profile names, you may choose to use one of them for pipeline run script:"
	@echo
	@find ./configs/opencv-ovms/cmd_client/res/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
	@echo
	@echo "Example: "
	@echo "PIPELINE_PROFILE=\"grpc_python\" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0"

clean-models:
	@find ./configs/opencv-ovms/models/2022/ -mindepth 1 -maxdepth 1 -type d -exec sudo rm -r {} \;

unit-test-profile-launcher:
	@cd ./configs/opencv-ovms/cmd_client && $(MAKE) unit-test