# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

.PHONY: build-all build-soc build-dgpu run-camera-simulator run-simulator run-USB-camera run-realsense run-video-file
# examples
# make run-realsense PLATFORM=core RUN_REALSENSE_ARGS=012345678901 EXTRA_PARAM="--color-width 1920 --color-height 1080 --color-framerate 15 --ocr 5 CPU"
# make down
# make clean

build-all: build-soc build-dgpu

build-soc:
	./docker-build.sh soc

build-dgpu:
	./docker-build.sh dgpu

run-camera-simulator:
	./camera-simulator/camera-simulator.sh

run-simulator: run-camera-simulator
	./docker-run.sh --platform $(PLATFORM) --inputsrc rtsp://127.0.0.1:8554/$(RUN_SIMULATOR_ARGS) $(EXTRA_PARAM)

run-USB-camera:
	./docker-run.sh --platform $(PLATFORM) --inputsrc /dev/$(RUN_USB_CAMERA_ARGS) $(EXTRA_PARAM)

run-realsense:
	./docker-run.sh --platform $(PLATFORM) --inputsrc $(RUN_REALSENSE_ARGS) --realsense_enabled $(EXTRA_PARAM)

run-video-file:
	./docker-run.sh --platform $(PLATFORM) --inputsrc file:$(RUN_VIDEO_FILE_ARGS) $(EXTRA_PARAM)

down:	
	if [ -z $$(docker ps  --filter="name=vision-self-checkout" -q -a) ]; then\
		 echo "nothing to clean up";\
	else\
		docker rm $$(docker ps  --filter="name=vision-self-checkout" -q -a) -f;\
	fi

down-simulator:
	if [ -z $$(docker ps  --filter="name=camera-simulator" -q -a) ]; then\
		 echo "nothing to clean up";\
	else\
		docker rm $$(docker ps  --filter="name=camera-simulator" -q -a) -f;\
	fi

clean: down down-simulator
