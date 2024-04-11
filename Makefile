# Copyright © 2024 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build-telegraf run-telegraf run-portainer clean-all clean-results clean-telegraf clean-models down-portainer
.PHONY: download-models clean-test run-demo

MKDOCS_IMAGE ?= asc-mkdocs
DGPU_TYPE ?= arc  # arc|flex

download-models:
	./models-downloader/downloadOVMSModels.sh

clean-models:
	@find ./models/ -mindepth 1 -maxdepth 1 -type d -exec sudo rm -r {} \;

run-smoke-tests:
	@echo "Running smoke tests for OVMS profiles"
	@./run_smoke_test.sh > smoke_tests_output.log
	@echo "results of smoke tests recorded in the file smoke_tests_output.log"
	@grep "Failed" ./smoke_tests_output.log || true
	@grep "===" ./smoke_tests_output.log || true

update-submodules:
	@git submodule update --init --recursive
	@git submodule update --remote --merge

run-demo: 
	@echo "Building automated self checkout app"	
	cd src && $(MAKE) build
	@echo "Downloading sample videos"
	cd performance-tools/benchmark-scripts && ./download_sample_videos.sh
	@echo "Running camera simulator"
	$(MAKE) run-camera-simulator
	@echo Running automated self checkout pipeline
	cd src && $(MAKE) run

get-realsense-serial-num:
	@./get-realsense-serialno.sh

build-telegraf:
	cd telegraf && $(MAKE) build

run-telegraf:
	cd telegraf && $(MAKE) run

run-portainer:
	docker compose -p portainer -f docker-compose-portainer.yml up -d

clean-telegraf: 
	./clean-containers.sh influxdb2
	./clean-containers.sh telegraf

down-portainer:
	docker compose -p portainer -f docker-compose-portainer.yml down

clean-all: 
	docker rm -f $(docker ps -aq)

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

clean-docs:
	rm -rf docs/
