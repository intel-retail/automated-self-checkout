# Copyright © 2024 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build build-realsense run down
.PHONY: build-telegraf run-telegraf run-portainer clean-all clean-results clean-telegraf clean-models down-portainer
.PHONY: update-submodules download-models run-demo run-headless

MKDOCS_IMAGE ?= asc-mkdocs
PIPELINE_COUNT ?= 1
INIT_DURATION ?= 30
TARGET_FPS ?= 14.95
CONTAINER_NAMES ?= gst0
DOCKER_COMPOSE ?= docker-compose.yml
DOCKER_COMPOSE_SENSORS ?= docker-compose-sensors.yml
DOCKER_COMPOSE_REGISTRY ?= docker-compose-reg.yml
RETAIL_USE_CASE_ROOT ?= $(PWD)
DENSITY_INCREMENT ?= 1
RESULTS_DIR ?= $(PWD)/benchmark
MODELDOWNLOADER_IMAGE ?= model-downloader-asc:latest
REGISTRY ?= true

# Registry image references
REGISTRY_MODEL_DOWNLOADER ?= intel/model-downloader-asc:latest
REGISTRY_PIPELINE_RUNNER ?= intel/pipeline-runner-asc:latest
REGISTRY_BENCHMARK ?= intel/retail-benchmark:latest

download-models: check-models-needed

check-models-needed:
	@chmod +x check_models.sh
	@echo "Checking if models need to be downloaded..."
	@if ./check_models.sh; then \
        echo "Models need to be downloaded. Proceeding..."; \
        $(MAKE) build-download-models; \
        $(MAKE) run-download-models; \
	else \
	    echo "Models already exist. Skipping download."; \
	fi

build-download-models:
	@if [ "$(REGISTRY)" = "true" ]; then \
        echo "Pulling prebuilt modeldownloader image from registry..."; \
		docker pull $(REGISTRY_MODEL_DOWNLOADER); \
		docker tag $(REGISTRY_MODEL_DOWNLOADER) $(MODELDOWNLOADER_IMAGE); \
	else \
        echo "Building modeldownloader image locally..."; \
        docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t $(MODELDOWNLOADER_IMAGE) -f download_models/Dockerfile .; \
	fi

run-download-models:
	docker run --rm \
        -e HTTP_PROXY=${HTTP_PROXY} \
        -e HTTPS_PROXY=${HTTPS_PROXY} \
        -e MODELS_DIR=/workspace/models \
        -v "$(shell pwd)/models:/workspace/models" \
        $(MODELDOWNLOADER_IMAGE)


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

build:
	@if [ "$(REGISTRY)" = "true" ]; then \
		echo "############### Not building locally, as registry mode is enabled ###############################"; \
	else \
		echo "Building pipeline-runner-asc img locally..."; \
		docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} --target build-default -t pipeline-runner-asc:latest -f src/Dockerfile src/; \
	fi
	

build-realsense:
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} --target build-realsense -t dlstreamer:realsense -f src/Dockerfile src/

build-pipeline-server: | download-models update-submodules download-sample-videos
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t dlstreamer:pipeline-server -f src/pipeline-server/Dockerfile.pipeline-server src/pipeline-server

build-sensors:
	docker compose -f src/${DOCKER_COMPOSE_SENSORS} build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} 

run:
	@if [ "$(REGISTRY)" = "true" ]; then \
        echo "Running registry version..."; \
        echo "############### Running registry mode ###############################"; \
        docker compose -f src/$(DOCKER_COMPOSE_REGISTRY) up -d; \
	else \
        echo "Running standard version..."; \
        echo "############### Running STANDARD mode ###############################"; \
        docker compose -f src/$(DOCKER_COMPOSE) up -d; \
	fi

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
	@if [ "$(REGISTRY)" = "true" ]; then \
        echo "Running registry version with render mode..."; \
        RENDER_MODE=1 docker compose -f src/$(DOCKER_COMPOSE_REGISTRY) up -d; \
	else \
        echo "Running standard version with render mode..."; \
        RENDER_MODE=1 docker compose -f src/$(DOCKER_COMPOSE) up -d; \
	fi

down:
	@if [ "$(REGISTRY)" = "true" ]; then \
		echo "Stopping registry demo containers..."; \
		docker compose -f src/$(DOCKER_COMPOSE_REGISTRY) down; \
		echo "Registry demo containers stopped and removed."; \
	else \
		docker compose -f src/$(DOCKER_COMPOSE) down; \
	fi

down-sensors:
	docker compose -f src/${DOCKER_COMPOSE_SENSORS} down

run-demo: | download-models update-submodules download-sample-videos
	@echo "Building automated self checkout app"	
	$(MAKE) build
	@echo Running automated self checkout pipeline
	@if [ "$(RENDER_MODE)" != "0" ]; then \
		$(MAKE) run-render-mode; \
	else \
		$(MAKE) run; \
	fi

run-headless: | download-models update-submodules download-sample-videos
	@echo "Building automated self checkout app"
	$(MAKE) build
	@echo Running automated self checkout pipeline
	$(MAKE) run

run-pipeline-server: | download-models update-submodules download-sample-videos
	RETAIL_USE_CASE_ROOT=$(RETAIL_USE_CASE_ROOT) docker compose -f src/pipeline-server/docker-compose.pipeline-server.yml up -d

down-pipeline-server:
	docker compose -f src/pipeline-server/docker-compose.pipeline-server.yml down

fetch-benchmark:
	@echo "Fetching benchmark image from registry..."
	docker pull $(REGISTRY_BENCHMARK)
	@echo "Benchmark image ready"

build-benchmark:
	@if [ "$(REGISTRY)" = "true" ]; then \
		$(MAKE) fetch-benchmark; \
	else \
		cd performance-tools && $(MAKE) build-benchmark-docker; \
	fi

benchmark: build-benchmark download-models download-sample-videos	
	cd performance-tools/benchmark-scripts && \
	python3 -m venv venv && \
	. venv/bin/activate && \
	pip install -r requirements.txt && \
	if [ "$(REGISTRY)" = "true" ]; then \
		python benchmark.py --compose_file ../../src/$(DOCKER_COMPOSE_REGISTRY) --pipeline $(PIPELINE_COUNT) --results_dir $(RESULTS_DIR) --benchmark_type reg; \
	else \
		python benchmark.py --compose_file ../../src/$(DOCKER_COMPOSE) --pipeline $(PIPELINE_COUNT) --results_dir $(RESULTS_DIR); \
	fi && \
	deactivate

benchmark-stream-density: build-benchmark download-models
	@if [ "$(OOM_PROTECTION)" = "0" ]; then \
		echo "╔════════════════════════════════════════════════════════════╗"; \
		echo "║ WARNING                                                    ║"; \
		echo "║                                                            ║"; \
		echo "║ OOM Protection is DISABLED. This test may:                 ║"; \
		echo "║ • Cause system instability or crashes                      ║"; \
		echo "║ • Require hard reboot if system becomes unresponsive       ║"; \
		echo "║ • Result in data loss in other applications                ║"; \
		echo "║                                                            ║"; \
		echo "║ Press Ctrl+C now to cancel, or wait 5 seconds...           ║"; \
		echo "╚════════════════════════════════════════════════════════════╝"; \
		sleep 5; \
	fi

	@if [ "$(REGISTRY)" = "true" ]; then \
		echo "Using registry mode - skipping benchmark container build..."; \
	else \
		echo "Building benchmark container locally..."; \
		$(MAKE) build-benchmark; \
	fi; \
	cd performance-tools/benchmark-scripts && \
	python3 -m venv venv && \
	. venv/bin/activate && \
	pip install -r requirements.txt && \
	if [ "$(REGISTRY)" = "true" ]; then \
		python3 benchmark.py \
			--compose_file ../../src/$(DOCKER_COMPOSE_REGISTRY) \
			--init_duration $(INIT_DURATION) \
			--target_fps $(TARGET_FPS) \
			--container_names $(CONTAINER_NAMES) \
			--density_increment $(DENSITY_INCREMENT) \
			--benchmark_type reg \
			--results_dir $(RESULTS_DIR); \
	else \
		python3 benchmark.py \
			--compose_file ../../src/$(DOCKER_COMPOSE) \
			--init_duration $(INIT_DURATION) \
			--target_fps $(TARGET_FPS) \
			--container_names $(CONTAINER_NAMES) \
			--density_increment $(DENSITY_INCREMENT) \
			--results_dir $(RESULTS_DIR); \
	fi; \
	deactivate

benchmark-quickstart: build-benchmark download-models download-sample-videos	
	cd performance-tools/benchmark-scripts && \
	python3 -m venv venv && \
	. venv/bin/activate && \
	pip install -r requirements.txt && \
	if [ "$(REGISTRY)" = "true" ]; then \
		DEVICE_ENV=res/all-gpu.env RENDER_MODE=0 PIPELINE_SCRIPT=obj_detection_age_prediction.sh \
		python benchmark.py --compose_file ../../src/docker-compose.yml --pipeline $(PIPELINE_COUNT) --results_dir $(RESULTS_DIR) --benchmark_type reg; \
	else \
		DEVICE_ENV=res/all-gpu.env RENDER_MODE=0 PIPELINE_SCRIPT=obj_detection_age_prediction.sh \
		python benchmark.py --compose_file ../../src/docker-compose.yml --pipeline $(PIPELINE_COUNT) --results_dir $(RESULTS_DIR); \
	fi && \
	deactivate
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
	@if [ -n "$$(docker ps -aq)" ]; then \
		docker rm -f $$(docker ps -aq); \
		echo "All containers removed."; \
	else \
		echo "No containers to remove."; \
	fi

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
