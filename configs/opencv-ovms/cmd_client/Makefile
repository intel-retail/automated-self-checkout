# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build unit-test

build:
	@echo "building executeable profile-launcher..."
	@go build -o profile-launcher
	@echo "done"

unit-test:
	go test -count=1 ./...
