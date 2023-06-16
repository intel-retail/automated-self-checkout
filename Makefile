# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

.PHONY: build-all build-soc build-dgpu run-camera-simulator clean clean-simulator clean-ovms-client clean-model-server clean-ovms clean-all

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

get-server-code:
	echo "Getting model_server code"
	git clone https://github.com/gsilva2016/model_server 

clean-ovms-client:
	./clean-containers.sh ovms-client

clean-model-server:
	./clean-containers.sh model-server

clean-ovms: clean-ovms-client clean-model-server

clean-all: clean clean-ovms clean-simulator

docs: clean-docs
	mkdocs build
	mkdocs serve -a localhost:8008

docs-builder-image:
	docker build \
		-f Dockerfile.docs \
		-t $(PROJECT)/mkdocs \
		.

build-docs: docs-builder-image
	docker run --rm \
		-v $(PWD):/docs \
		-w /docs \
		$(PROJECT)/mkdocs \
		build

serve-docs: docs-builder-image
	docker run --rm \
		-it \
		-p 8008:8000 \
		-v $(PWD):/docs \
		-w /docs \
		$(PROJECT)/mkdocs

clean-docs:
	rm -rf docs/
