#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip  
pip3 install -r requirements.txt

if [ -d "/opt/intel/pcm" ]
then
        rm -R /opt/intel/pcm
fi

echo "Installing IOTOP"
apt --yes install iotop
ret=$?
if [ $ret -ne 0 ]; then
	echo "ERROR: IOTOP install was NOT successful"
	exit 1
fi

#install SAR
echo "Installing SAR"
apt --yes install sysstat -y
ret=$?
if [ $ret -ne 0 ]; then
	echo "ERROR: SAR install was NOT successful"
	exit 1
fi

#install jq
echo "Installing jq"
apt --yes install jq
ret=$?
if [ $ret -ne 0 ]; then
        echo "ERROR: jq install was NOT successful"
        exit 1
fi

#install curl 
echo "Installing curl"
apt --yes install curl
ret=$?
if [ $ret -ne 0 ]; then
	echo "ERROR: curl install was NOT successful"
	exit 1
fi

#install cmake for building pcm
echo "Installing cmake"
apt --yes install cmake
ret=$?
if [ $ret -ne 0 ]; then
	echo "ERROR: cmake install was NOT successful"
	exit 1
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


#install xpumanager
server_gpu=`dmesg | grep -i "class 0x038000" | grep "8086"`

#echo "return is: $server_gpu"
if grep -q "class" <<< "$server_gpu"; then
        echo "Install xpumanager"
	wget https://github.com/intel/xpumanager/releases/download/V1.2.3/xpumanager_1.2.3_20230221.054746.0e2d4bfb+ubuntu22.04_amd64.deb
        apt --yes install intel-gsc 
        apt --yes install level-zero
        apt --yes install intel-level-zero-gpu
        sudo dpkg -i ./xpumanager_1.2.3_20230221.054746.0e2d4bfb+ubuntu22.04_amd64.deb

else
        echo "Do not install xpumanager"
fi
