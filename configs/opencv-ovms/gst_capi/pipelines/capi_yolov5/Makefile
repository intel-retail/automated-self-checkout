#
# Copyright (c) 2023 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

.PHONY: build_binary build

CV_LIBS = -L/usr/lib/x86_64-linux-gnu/ -L/usr/local/lib/x86_64-linux-gnu/ -L/ovms/lib/
CV_INCLUDES = -I/usr/lib/include/opencv4

OVMS_CPP_DOCKER_IMAGE ?= openvino/model_server
OVMS_CPP_IMAGE_TAG ?= latest

build_binary:
	g++ main.cpp -I/usr/include/gstreamer-1.0/usr/lib/x86_64-linux-gnu/ -I/usr/local/include/gstreamer-1.0 -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -I/usr/include/gstreamer-1.0/ -I/ovms/include $(CV_INCLUDES) $(CV_LIBS) -L/usr/lib/x86_64-linux-gnu/gstreamer-1.0 -lgstbase-1.0 -lgobject-2.0 -lglib-2.0 -lgstreamer-1.0 -lgstapp-1.0 -lopencv_imgcodecs -lopencv_imgproc -lopencv_videoio -lopencv_core -lopencv_videoio_gstreamer -lovms_shared -lopencv_highgui -lpthread -fPIC --std=c++17 -o capi_yolov5

build:
	# Build CAPI docker image
	docker build $(NO_CACHE_OPTION) -f Dockerfile.capi_yolov5 ../../../ \
		--build-arg http_proxy=$(HTTP_PROXY) \
		--build-arg https_proxy="$(HTTPS_PROXY)" \
		--build-arg no_proxy=$(NO_PROXY) \
		--build-arg BASE_IMAGE=ubuntu:22.04 \
		--progress=plain \
		-t $(OVMS_CPP_DOCKER_IMAGE)-capi-yolov5:$(OVMS_CPP_IMAGE_TAG)