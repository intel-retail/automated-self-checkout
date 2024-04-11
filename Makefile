# Copyright © 2024 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build-telegraf run-telegraf run-portainer clean-all clean-results clean-telegraf clean-models down-portainer
.PHONY: download-models clean-test run-demo stop-demo

MKDOCS_IMAGE ?= asc-mkdocs
DGPU_TYPE ?= arc  # arc|flex
PIPELINE_COUNT?= 1
PIPELINE_SCRIPT ?= yolov5s_full.sh
TARGET_FPS ?= 14.95

download-models:
	./download_models/downloadModels.sh

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

run-demo: download-models
	@echo "Building automated self checkout app"	
	cd src && $(MAKE) build
	@echo "Downloading sample videos"
	cd performance-tools/benchmark-scripts && ./download_sample_videos.sh
	@echo Running automated self checkout pipeline
	cd src && $(MAKE) run-render-mode

stop-demo:
	cd src && $(MAKE) down

build-benchmark:
	cd performance-tools && $(MAKE) build-benchmark-docker

benchmark: download-models
	cd performance-tools/benchmark-scripts && PIPELINE_SCRIPT=$(PIPELINE_SCRIPT) python benchmark.py --compose_file ../../src/docker-compose.yml --pipeline $(PIPELINE_COUNT)

benchmark-stream-density: download-models
	cd performance-tools/benchmark-scripts && PIPELINE_SCRIPT=$(PIPELINE_SCRIPT) python benchmark.py --compose_file ../../src/docker-compose.yml --target_fps $(TARGET_FPS)

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

clean-results:
	sudo rm -rf results/*

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
