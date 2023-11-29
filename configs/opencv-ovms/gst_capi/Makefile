# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build_face_detection build_capi_yolov5 build_capi_yolov5_ensemble

OVMS_CPP_DOCKER_IMAGE ?= openvino/model_server
OVMS_CPP_IMAGE_TAG ?= latest

build_face_detection:
	# Build CAPI docker image
	docker build $(NO_CACHE_OPTION) -f Dockerfile.ovms-capi-gst ../ \
		--build-arg http_proxy=$(HTTP_PROXY) \
		--build-arg https_proxy="$(HTTPS_PROXY)" \
		--build-arg no_proxy=$(NO_PROXY) \
		--build-arg BASE_IMAGE=ubuntu:22.04 \
		--build-arg PIPELINE_NAME=face_detection \
		--progress=plain \
		-t $(OVMS_CPP_DOCKER_IMAGE)-capi-gst-ovms-face_detection:$(OVMS_CPP_IMAGE_TAG)

build_capi_yolov5:
	# Build CAPI docker image
	docker build $(NO_CACHE_OPTION) -f Dockerfile.ovms-capi-gst ../ \
		--build-arg http_proxy=$(HTTP_PROXY) \
		--build-arg https_proxy="$(HTTPS_PROXY)" \
		--build-arg no_proxy=$(NO_PROXY) \
		--build-arg BASE_IMAGE=ubuntu:22.04 \
		--build-arg PIPELINE_NAME=capi_yolov5 \
		--progress=plain \
		-t $(OVMS_CPP_DOCKER_IMAGE)-capi-gst-ovms-capi_yolov5:$(OVMS_CPP_IMAGE_TAG)

build_capi_yolov5_ensemble:
	docker build $(NO_CACHE_OPTION) -f Dockerfile.ovms-capi-gst ../ \
		--build-arg http_proxy=$(HTTP_PROXY) \
		--build-arg https_proxy="$(HTTPS_PROXY)" \
		--build-arg no_proxy=$(NO_PROXY) \
		--build-arg BASE_IMAGE=ubuntu:22.04 \
		--build-arg PIPELINE_NAME=capi_yolov5_ensemble \
		--progress=plain \
		-t $(OVMS_CPP_DOCKER_IMAGE)-capi-gst-ovms-capi_yolov5_ensemble:$(OVMS_CPP_IMAGE_TAG)