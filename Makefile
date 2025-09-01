# Copyright © 2024 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build build-realsense run down
.PHONY: build-telegraf run-telegraf run-portainer clean-all clean-results clean-telegraf clean-models down-portainer
.PHONY: download-models clean-test run-demo run-headless

MKDOCS_IMAGE ?= asc-mkdocs
PIPELINE_COUNT ?= 1
INIT_DURATION ?= 30
TARGET_FPS ?= 14.95
CONTAINER_NAMES ?= gst0
DOCKER_COMPOSE ?= docker-compose.yml
DOCKER_COMPOSE_SENSORS ?= docker-compose-sensors.yml
RETAIL_USE_CASE_ROOT ?= $(PWD)
DENSITY_INCREMENT ?= 1
RESULTS_DIR ?= $(PWD)/benchmark

download-models: | build-download-models run-download-models

build-download-models:
	docker build  --build-arg  HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t modeldownloader -f download_models/Dockerfile .

run-download-models:
	docker run --rm -e HTTP_PROXY=${HTTP_PROXY} -e HTTPS_PROXY=${HTTPS_PROXY} -e MODELS_DIR=/workspace/models -v "$(shell pwd)/models:/workspace/models" modeldownloader

download-sample-videos:
	cd performance-tools/benchmark-scripts && ./download_sample_videos.sh

clean-models:
	@find ./models/ -mindepth 1 -maxdepth 1 -type d -exec sudo rm -r {} \;

run-smoke-tests: | download-models update-submodules download-sample-videos
	@echo "Running smoke tests for OVMS profiles"
	@./smoke_test.sh > smoke_tests_output.log
	@echo "results of smoke tests recorded in the file smoke_tests_output.log"
	@grep "Failed" ./smoke_tests_output.log || true
	@grep "===" ./smoke_tests_output.log || true

update-submodules:
	@git submodule update --init --recursive
	@git submodule update --remote --merge

build:
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} --target build-default -t dlstreamer:dev -f src/Dockerfile src/

build-realsense:
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} --target build-realsense -t dlstreamer:realsense -f src/Dockerfile src/

build-pipeline-server: | download-models update-submodules download-sample-videos
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t dlstreamer:pipeline-server -f src/pipeline-server/Dockerfile.pipeline-server src/pipeline-server

build-sensors:
	docker compose -f src/${DOCKER_COMPOSE_SENSORS} build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} 

run:
	docker compose -f src/$(DOCKER_COMPOSE) up -d

run-sensors:
	docker compose -f src/${DOCKER_COMPOSE_SENSORS} up -d


run-render-mode:
	@if [ -z "$(DISPLAY)" ] || ! echo "$(DISPLAY)" | grep -qE "^:[0-9]+(\.[0-9]+)?$$"; then \
		echo "ERROR: Invalid or missing DISPLAY environment variable."; \
		echo "Please set DISPLAY in the format ':<number>' (e.g., ':0')."; \
		echo "Usage: make <target> DISPLAY=:<number>"; \
		echo "Example: make $@ DISPLAY=:0"; \
		exit 1; \
	fi
	@echo "Using DISPLAY=$(DISPLAY)"
	@xhost +local:docker
	@RENDER_MODE=1 docker compose -f src/$(DOCKER_COMPOSE) up -d


down:
	docker compose -f src/$(DOCKER_COMPOSE) down

down-sensors:
	docker compose -f src/${DOCKER_COMPOSE_SENSORS} down

run-demo: | download-models update-submodules download-sample-videos
	@echo "Building automated self checkout app"	
	$(MAKE) build
	@echo Running automated self checkout pipeline
	$(MAKE) run-render-mode

run-headless: | download-models update-submodules download-sample-videos
	@echo "Building automated self checkout app"
	$(MAKE) build
	@echo Running automated self checkout pipeline
	$(MAKE) run

run-pipeline-server: | download-models update-submodules download-sample-videos
	RETAIL_USE_CASE_ROOT=$(RETAIL_USE_CASE_ROOT) docker compose -f src/pipeline-server/docker-compose.pipeline-server.yml up -d

down-pipeline-server:
	docker compose -f src/pipeline-server/docker-compose.pipeline-server.yml down

build-benchmark:
	cd performance-tools && $(MAKE) build-benchmark-docker

benchmark: download-models update-submodules build-benchmark download-sample-videos
	cd performance-tools/benchmark-scripts && \
	pip3 install -r requirements.txt && \
	python3 benchmark.py --compose_file ../../src/docker-compose.yml --pipeline $(PIPELINE_COUNT) --results_dir $(RESULTS_DIR)

benchmark-stream-density: build-benchmark download-models
	@cd performance-tools/benchmark-scripts && \
	python3 benchmark.py \
	  --compose_file ../../src/docker-compose.yml \
	  --init_duration $(INIT_DURATION) \
	  --target_fps $(TARGET_FPS) \
	  --container_names $(CONTAINER_NAMES) \
	  --density_increment $(DENSITY_INCREMENT) \
	  --results_dir $(RESULTS_DIR)

benchmark-quickstart: 
	DEVICE_ENV=res/all-gpu.env RENDER_MODE=0 PIPELINE_SCRIPT=obj_detection_age_prediction.sh $(MAKE) benchmark
	$(MAKE) consolidate-metrics

build-telegraf:
	cd telegraf && $(MAKE) build

run-telegraf:
	cd telegraf && $(MAKE) run

clean-telegraf: 
	./clean-containers.sh influxdb2
	./clean-containers.sh telegraf

run-portainer:
	docker compose -p portainer -f docker-compose-portainer.yml up -d

down-portainer:
	docker compose -p portainer -f docker-compose-portainer.yml down

clean-results:
	rm -rf results/*

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

helm-package:
	helm package helm/ -u -d .deploy
	helm package helm/
	helm repo index .
	helm repo index --url https://github.com/intel-retail/automated-self-checkout .

consolidate-metrics:
	cd performance-tools/benchmark-scripts && \
	( \
	python3 -m venv venv && \
	. venv/bin/activate && \
	pip install -r requirements.txt && \
	python3 consolidate_multiple_run_of_metrics.py --root_directory $(RESULTS_DIR) --output $(RESULTS_DIR)/metrics.csv && \
	deactivate \
	)

plot-metrics:
	cd performance-tools/benchmark-scripts && \
	( \
	python3 -m venv venv && \
	. venv/bin/activate && \
	pip install -r requirements.txt && \
	python3 usage_graph_plot.py --dir $(RESULTS_DIR)  && \
	deactivate \
	)
