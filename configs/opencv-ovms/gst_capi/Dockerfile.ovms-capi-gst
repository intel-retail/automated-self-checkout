#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# -----------------------------------------------------------
ARG BASE_IMAGE=openvino/model_server:2023.1-gpu
FROM $BASE_IMAGE as release
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]
WORKDIR /

# Install dependencies for compiling ocv4.7.0
ARG BUILD_DEPENDENCIES="cmake build-essential git-gui python3 python3-pip flex bison clang libgtk2.0-dev libhdf5-serial-dev libvtk9-dev libtbb2 libxml2 curl libpugixml1v5"

ARG GSTREAMER="libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio gstreamer1.0-plugins-base-apps"

RUN apt -y update && \
    apt install -y ${BUILD_DEPENDENCIES} ${GSTREAMER} && \
    rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*

# Install GPU drivers for Arc. Note replace arc with flex/max below
ARG DGPU_TYPE="arc"
RUN apt update -y; apt install -y wget curl vim gpg-agent; wget -qO - https://repositories.intel.com/graphics/intel-graphics.key | gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg; echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/graphics/ubuntu jammy $DGPU_TYPE" | tee /etc/apt/sources.list.d/intel-gpu-jammy.list; apt update -y; DEBIAN_FRONTEND=noninteractive apt-get install -y \
intel-opencl-icd intel-level-zero-gpu level-zero intel-media-va-driver-non-free libmfx1 libmfxgen1 libvpl2 libegl-mesa0 libegl1-mesa libegl1-mesa-dev libgbm1 libgl1-mesa-dev libgl1-mesa-dri libglapi-mesa libgles2-mesa-dev libglx-mesa0 libigdgmm12 libxatracker2 mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers va-driver-all vainfo libcanberra-gtk-module

# Install GST dependencies
RUN apt -y update; DEBIAN_FRONTEND=noninteractive apt install -y libva-dev autoconf libtool libpciaccess-dev libssl-dev pkg-config libdrm-dev libgbm-dev libcogl-pango-dev libudev-dev lld libx11-xcb-dev libpciaccess-dev nasm yasm libx11-dev libxcb-present-dev libxcb-dri3-dev xorg xorg-dev libgl1-mesa-glx libgl1-mesa-dev meson libgudev-1.0-dev

# Install OneVPL CPU & GPU Support
RUN apt -y update; DEBIAN_FRONTEND=noninteractive apt install -y wget unzip
RUN wget https://github.com/intel/libvpl/archive/refs/tags/v2023.3.1.zip && \
    unzip v2023.3.1.zip && \
    cd libvpl-2023.3.1; export VPL_INSTALL_DIR=/opt/intel/onevpl; mkdir _build; mkdir $VPL_INSTALL_DIR; cd _build; cmake .. -DCMAKE_INSTALL_PREFIX=$VPL_INSTALL_DIR; cmake --build . --config Release; cmake --build . --config Release --target install

RUN wget https://github.com/oneapi-src/oneVPL-intel-gpu/archive/refs/tags/intel-onevpl-23.2.4.zip
RUN unzip intel-onevpl-23.2.4.zip
RUN cd oneVPL-intel-gpu*; mkdir build; cd build; cmake ..; make -j`nproc`; make install

# Build OCV 4.7.0 with GST HW Accel
RUN opencv_branch=${opencv_branch:-4.7.0}; \
work_dir=${work_dir:-/opt}; \
current_working_dir=$(pwd); \
cd $work_dir; \
git clone https://github.com/opencv/opencv.git --depth 1 -b $opencv_branch $work_dir/opencv_repo; \
git clone https://github.com/opencv/opencv_contrib.git; \
cd $work_dir/opencv_contrib; git checkout -b 4.7.0 4.7.0; \
cd $work_dir/opencv_repo; \
mkdir -p $work_dir/opencv_repo/build; \
cd $work_dir/opencv_repo/build; \
cmake \
-D OPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib/modules \
-D VIDEOIO_PLUGIN_LIST=gstreamer \
-D WITH_GSTREAMER=ON \
-D WITH_FFMPEG=OFF \
-D CMAKE_BUILD_TYPE=Release \
-D CMAKE_INSTALL_PREFIX=/usr/lib \
-D OPENCV_LIB_INSTALL_PATH=x86_64-linux-gnu \
-D WITH_OPENJPEG=OFF \
-D WITH_JASPER=OFF \
-D WITH_OPENEXR=OFF \
-D WITH_TIFF=OFF \
-D WITH_GTK=ON $work_dir/opencv_repo && \
make "-j10" && \
make install

RUN wget -O ovms.tar.gz https://github.com/openvinotoolkit/model_server/releases/download/v2023.1/ovms_ubuntu22.tar.gz
RUN tar -xf ovms.tar.gz
RUN rm /ovms/lib/*opencv*;


# Copy C-API sources
#RUN mv model_repo configs
RUN DEBIAN_FRONTEND=noninteractive apt install -y jq -y && \
    rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*

ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/:/usr/local/lib/x86_64-linux-gnu/:/usr/local/lib:/ovms/lib:$LD_LIBRARY_PATH
COPY gst_capi/pipelines /home/intel/gst-ovms/pipelines
COPY gst_capi/launch-pipeline.sh /home/intel/gst-ovms/launch-pipeline.sh
COPY gst_capi/run_gst_capi.sh /home/intel/gst-ovms/run_gst_capi.sh
ARG PIPELINE_NAME
RUN echo $PIPELINE_NAME; cd /home/intel/gst-ovms/pipelines/$PIPELINE_NAME; make build

USER ovms
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/:/usr/local/lib/x86_64-linux-gnu/:/usr/local/lib:/ovms/lib:$LD_LIBRARY_PATH

# Enable HWA decoder for OpenCV using GST use cases
ENV OPENCV_FFMPEG_CAPTURE_OPTIONS="hw_decoders_any;vaapi"

WORKDIR /home/intel/gst-ovms/
