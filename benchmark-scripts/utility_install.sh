#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

pip3 install -r requirements.txt

if [ -d "/opt/intel/pcm" ]
then
        rm -R /opt/intel/pcm
fi


PCM_DIRECTORY=/opt/intel
echo "Installing PCM"
[ ! -d "$PCM_DIRECTORY" ] && mkdir -p "$PCM_DIRECTORY"
cd $PCM_DIRECTORY
git clone --recursive https://github.com/opcm/pcm.git
ret=$?
if [ $ret -ne 0 ]; then
        echo "ERROR: git clone of PCM was NOT successful"
        exit 1
fi

#if the checkout was good then build PCM
cd pcm
mkdir build
cd build
cmake ..
cmake --build .

if [ $ret -ne 0 ]; then
        echo "ERROR: build of PCM was NOT successful"
        exit 1
fi
