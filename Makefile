# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build-dlstreamer build-dlstreamer-realsense build-grpc-python build-grpc-go build-python-apps build-telegraf
.PHONY: build-capi_face_detection build-capi_yolov5 build-capi_yolov5_ensemble
.PHONY: run-camera-simulator run-telegraf run-portainer run-pipelines
.PHONY: clean-grpc-go clean-segmentation clean-ovms clean-all clean-results clean-telegraf clean-models clean-webcam
.PHONY: clean-ovms-server-configs clean-ovms-server
.PHONY: down-portainer down-pipelines
.PHONY: clean clean-simulator clean-object-detection clean-classification clean-gst clean-capi_face_detection clean-capi_yolov5 clean-capi_yolov5_ensemble
.PHONY: list-profiles
.PHONY: unit-test-profile-launcher build-profile-launcher profile-launcher-status clean-profile-launcher webcam-rtsp
.PHONY: clean-test
.PHONY: hadolint
.PHONY: get-realsense-serial-num
.PHONY: run-demo run-cached-demo

MKDOCS_IMAGE ?= asc-mkdocs
DGPU_TYPE ?= arc  # arc|flex
DOCKER_COMPOSE ?= docker-compose.yml

build-dlstreamer:
	docker build --no-cache --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} --target build-default -t dlstreamer:dev -f Dockerfile.dlstreamer .

build-dlstreamer-realsense:
	docker build --no-cache --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} --target build-realsense -t dlstreamer:realsense -f Dockerfile.dlstreamer .

get-realsense-serial-num:
	@./get-realsense-serialno.sh

build-telegraf:
	cd telegraf && $(MAKE) build

run-camera-simulator:
	./camera-simulator/camera-simulator.sh

run-telegraf:
	cd telegraf && $(MAKE) run

run-portainer:
	docker compose -p portainer -f docker-compose-portainer.yml up -d

run-pipelines:
	@./scripts/gen_ovms_model_config_json.sh
	docker compose -f $(DOCKER_COMPOSE) up -d

clean:
	./clean-containers.sh automated-self-checkout

clean-simulator:
	./clean-containers.sh camera-simulator

build-profile-launcher:
	@mkdir -p ./results || true
	@cd ./configs/opencv-ovms/cmd_client && $(MAKE) build
	@./create-symbolic-link.sh $(PWD)/configs/opencv-ovms/cmd_client/profile-launcher profile-launcher
	@./create-symbolic-link.sh $(PWD)/configs/opencv-ovms/scripts scripts
	@./create-symbolic-link.sh $(PWD)/configs/opencv-ovms/envs envs
	@./create-symbolic-link.sh $(PWD)/benchmark-scripts/stream_density.sh stream_density.sh

build-ovms-server:
	HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY} docker pull openvino/model_server:2023.1-gpu

clean-profile-launcher: clean-grpc-python clean-grpc-go clean-segmentation clean-object-detection clean-classification clean-gst clean-capi_face_detection clean-test clean-capi_yolov5 clean-capi_yolov5_ensemble
	@echo "containers launched by profile-launcher are cleaned up."
	@pkill -9 profile-launcher || true

profile-launcher-status:
	$(eval profileLauncherPid = $(shell ps -aux | grep ./profile-launcher | grep -v grep))
	$(if $(strip $(profileLauncherPid)), @echo "$@: profile-launcher running: "$(profileLauncherPid), @echo "$@: profile laucnher stopped")

clean-test:
	./clean-containers.sh test

clean-grpc-python:
	./clean-containers.sh grpc_python

clean-grpc-go:
	./clean-containers.sh grpc_go

clean-gst:
	./clean-containers.sh gst

clean-segmentation:
	./clean-containers.sh segmentation

clean-object-detection:
	./clean-containers.sh object-detection

clean-classification:
	./clean-containers.sh classification

clean-ovms-server: clean-ovms-server-configs
	./clean-containers.sh ovms-server

clean-ovms: clean-profile-launcher clean-ovms-server

clean-capi_face_detection:
	./clean-containers.sh capi_face_detection

clean-capi_yolov5:
	./clean-containers.sh capi_yolov5

clean-capi_yolov5_ensemble:
	./clean-containers.sh capi_yolov5_ensemble

clean-telegraf: 
	./clean-containers.sh influxdb2
	./clean-containers.sh telegraf

clean-webcam:
	./clean-containers.sh webcam

down-portainer:
	docker compose -p portainer -f docker-compose-portainer.yml down

down-pipelines:
	docker compose -f docker-compose.yml down
	@if [ -f ./configs/opencv-ovms/models/2022/config.json ]; then rm ./configs/opencv-ovms/models/2022/config.json; fi;

clean-all: clean clean-ovms clean-simulator clean-results clean-telegraf clean-webcam down-pipelines

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
	cd configs/opencv-ovms/grpc_go && $(MAKE) build

build-python-apps: build-profile-launcher
	cd configs/opencv-ovms/demos && make build	

build-capi_face_detection: build-profile-launcher
	cd configs/opencv-ovms/gst_capi && DGPU_TYPE=$(DGPU_TYPE) $(MAKE) build_face_detection

build-capi_yolov5: build-profile-launcher
	cd configs/opencv-ovms/gst_capi && DGPU_TYPE=$(DGPU_TYPE) $(MAKE) build_capi_yolov5

build-capi_yolov5_ensemble: build-profile-launcher
	cd configs/opencv-ovms/gst_capi && DGPU_TYPE=$(DGPU_TYPE) $(MAKE) build_capi_yolov5_ensemble

clean-docs:
	rm -rf docs/

clean-results:
	sudo rm -rf results/*

clean-ovms-server-configs:
	@find ./configs/opencv-ovms/models/2022/ -mindepth 1 -maxdepth 1 -name 'config_ovms-server*.json' -delete

list-profiles:
	@echo "Here is the list of profile names, you may choose to use one of them for pipeline run script:"
	@echo
	@find ./configs/opencv-ovms/cmd_client/res/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
	@echo
	@echo "Example: "
	@echo "PIPELINE_PROFILE=\"grpc_python\" sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0"

clean-models:
	@find ./configs/opencv-ovms/models/2022/ -mindepth 1 -maxdepth 1 -type d -exec sudo rm -r {} \;

unit-test-profile-launcher:
	@cd ./configs/opencv-ovms/cmd_client && $(MAKE) unit-test

webcam-rtsp:
	docker run --rm \
		-v $(PWD)/camera-simulator/mediamtx.yml:/mediamtx.yml \
		-d \
		-p 8554:8554 \
		--device=/dev/video0 \
		--name webcam \
		bluenviron/mediamtx:latest-ffmpeg		

run-smoke-tests:
	@echo "Running smoke tests for OVMS profiles"
	@./run_smoke_test.sh > smoke_tests_output.log
	@echo "results of smoke tests recorded in the file smoke_tests_output.log"
	@grep "Failed" ./smoke_tests_output.log || true
	@grep "===" ./smoke_tests_output.log || true

hadolint:
	@echo "Run hadolint..."
	@docker run --rm -v `pwd`:/automated-self-checkout --entrypoint /bin/hadolint hadolint/hadolint:latest \
	--config /automated-self-checkout/.github/.hadolint.yaml \
	`sudo find * -type f -name 'Dockerfile*' | xargs -i echo '/automated-self-checkout/{}'` | grep error \
	| grep -v model_server \
	|| echo "no issue found"

run-demo: 
	@echo "Building python apps"	
	$(MAKE) build-python-apps
	@echo "Downloading sample videos"
	cd benchmark-scripts && ./download_sample_videos.sh
	@echo "Running camera simulator"
	$(MAKE) run-camera-simulator
	@echo Running Object_detection gRPC pipeline
	PIPELINE_PROFILE="object_detection" RENDER_MODE=1 sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_1

run-cached-demo:
	@echo "Running camera simulator"
	$(MAKE) run-camera-simulator
	@echo Running Object_detection gRPC pipeline
	PIPELINE_PROFILE="object_detection" RENDER_MODE=1 sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_1
