# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build run

build:
	docker build --build-arg IS_FLEX=${IS_FLEX} -t intel-telegraf:1.0 .

run:
	./docker-run.sh
