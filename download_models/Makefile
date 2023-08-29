# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build

build:
	docker build --tag download_models:dev -f Dockerfile.downloadModels .

run:
	docker run --net host --rm -v "$$PWD/../configs/opencv-ovms/models/2022/modelslist:/output" -e PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python download_models:dev