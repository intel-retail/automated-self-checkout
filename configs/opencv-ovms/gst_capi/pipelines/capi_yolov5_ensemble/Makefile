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

CV_LIBS = -L/usr/lib/x86_64-linux-gnu/ -L/usr/local/lib/x86_64-linux-gnu/ -L/ovms/lib/
CV_INCLUDES = -I/usr/lib/include/opencv4
CUSTOM_NODE_FLAGS = -fpic -O2 -U_FORTIFY_SOURCE -fstack-protector -fno-omit-frame-pointer -D_FORTIFY_SOURCE=1 -fno-strict-overflow -Wall -Wno-unknown-pragmas -Wno-error=sign-compare -fno-delete-null-pointer-checks -fwrapv -fstack-clash-protection  -Wformat -Wformat-security

build:
	g++ -c -std=c++17 efficientnetb0_node.cpp ${CUSTOM_NODE_FLAGS} ${CV_INCLUDES}
	
	g++ -shared ${CUSTOM_NODE_FLAGS} -o libcustom_node_efficientnetb0-yolov5.so efficientnetb0_node.o ${CV_LIBS} ${CV_INCLUDES} -lopencv_core -lopencv_imgproc -lopencv_imgcodecs
	cp libcustom_node_efficientnetb0-yolov5.so /ovms/lib/

	g++ barcode.cpp main.cpp -I/usr/include/gstreamer-1.0/usr/lib/x86_64-linux-gnu/ -I/usr/local/include/gstreamer-1.0 -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -I/usr/include/gstreamer-1.0/ -I/ovms/include $(CV_INCLUDES) $(CV_LIBS) -L/usr/lib/x86_64-linux-gnu/gstreamer-1.0 -lgstbase-1.0 -lgobject-2.0 -lglib-2.0 -lgstreamer-1.0 -lgstapp-1.0 -lopencv_imgcodecs -lopencv_imgproc -lopencv_videoio -lopencv_core -lopencv_videoio_gstreamer -lovms_shared -lopencv_highgui -lpthread -lopencv_barcode -fPIC --std=c++17 -o capi_yolov5_ensemble

