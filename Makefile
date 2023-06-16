# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

.PHONY: build-all build-soc build-dgpu run-camera-simulator clean clean-simulator clean-all docs docs-builder-image build-docs serve-docs clean-docs
PROJECT=automated-self-checkout

build-all: build-soc build-dgpu

build-soc:
	./docker-build.sh soc ${HTTP_PROXY} ${HTTPS_PROXY}

build-dgpu:
	./docker-build.sh dgpu ${HTTP_PROXY} ${HTTPS_PROXY}

run-camera-simulator:
	./camera-simulator/camera-simulator.sh

clean:
	if [ -z $$(docker ps  --filter="name=automated-self-checkout" -q -a) ]; then\
		 echo "nothing to clean up";\
	else\
		docker rm $$(docker ps  --filter="name=automated-self-checkout" -q -a) -f;\
	fi

clean-simulator:
	if [ -z $$(docker ps  --filter="name=camera-simulator" -q -a) ]; then\
		 echo "nothing to clean up";\
	else\
		docker rm $$(docker ps  --filter="name=camera-simulator" -q -a) -f;\
	fi

clean-all: clean clean-simulator

docs: clean-docs
	mkdocs build
	mkdocs serve -a localhost:8008

docs-builder-image:
	docker build \
		-f Dockerfile.docs \
		-t $(PROJECT)/mkdocs \
		.

build-docs: docs-builder-image
	docker run --rm \
		-v $(PWD):/docs \
		-w /docs \
		$(PROJECT)/mkdocs \
		build

serve-docs: docs-builder-image
	docker run --rm \
		-it \
		-p 8008:8000 \
		-v $(PWD):/docs \
		-w /docs \
		$(PROJECT)/mkdocs

clean-docs:
	rm -rf docs/