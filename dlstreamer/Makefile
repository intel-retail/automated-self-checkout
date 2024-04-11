# Copyright © 2024 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
.PHONY: build build-realsense run down

DOCKER_COMPOSE ?= docker-compose_dlstreamer.yml
PIPELINE_SCRIPT ?= yolov5s.sh
PIPELINE_COUNT ?= 1
RETAIL_USE_CASE_ROOT ?= ../..
RESULTS_DIR ?= ../../results

build:
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} --target build-default -t dlstreamer:dev -f Dockerfile .

build-realsense:
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} --target build-realsense -t dlstreamer:realsense -f Dockerfile .

run:
	PIPELINE_SCRIPT=$(PIPELINE_SCRIPT) PIPELINE_COUNT=$(PIPELINE_COUNT) RETAIL_USE_CASE_ROOT="$(RETAIL_USE_CASE_ROOT)" RESULTS_DIR="$(RESULTS_DIR)" docker compose -f $(DOCKER_COMPOSE) up -d

down:
	PIPELINE_SCRIPT=$(PIPELINE_SCRIPT) PIPELINE_COUNT=$(PIPELINE_COUNT) RETAIL_USE_CASE_ROOT="$(RETAIL_USE_CASE_ROOT)" RESULTS_DIR="$(RESULTS_DIR)" docker compose -f $(DOCKER_COMPOSE) down
