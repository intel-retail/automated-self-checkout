# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

.PHONY: build-all build-soc build-dgpu run-camera-simulator clean clean-simulator clean-all

build-all: build-soc build-dgpu

build-soc:
	./docker-build.sh soc

build-dgpu:
	./docker-build.sh dgpu

run-camera-simulator:
	./camera-simulator/camera-simulator.sh

clean:
	if [ -z $$(docker ps  --filter="name=vision-self-checkout" -q -a) ]; then\
		 echo "nothing to clean up";\
	else\
		docker rm $$(docker ps  --filter="name=vision-self-checkout" -q -a) -f;\
	fi

clean-simulator:
	if [ -z $$(docker ps  --filter="name=camera-simulator" -q -a) ]; then\
		 echo "nothing to clean up";\
	else\
		docker rm $$(docker ps  --filter="name=camera-simulator" -q -a) -f;\
	fi

clean-all: clean clean-simulator
