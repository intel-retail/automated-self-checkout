#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

if [ -z $1 ]
then
	echo "
	Builds not requiring network proxy
	 usage: ./docker-build.sh dgpu|soc
	
	Optional: Builds requiring network proxy
	 usage: ./docker-build.sh dgpu|soc http_proxy_ip:http_proxy_port https_proxy_ip:https_proxy_port
	"
	exit 0
fi

httpp=$2
httpps=$3

# ./docker-build.sh dgpu http://proxy-chain.intel.com:911 http://proxy-chain.intel.com:912

if [ -f intel-graphics.key ] 
then
	rm intel-graphics.key
fi
wget https://repositories.intel.com/graphics/intel-graphics.key 

if [ x$1 == "xdgpu" ] 
then
	echo "Building for dgpu Arc/Flex"
	docker build --no-cache --build-arg HTTPS_PROXY=$httpps --build-arg HTTP_PROXY=$httpp -t sco-dgpu:2.0 -f Dockerfile.dgpu .
else
	echo "Building for SOC (e.g. TGL/ADL/Xeon SP/etc)"
	docker build --no-cache --build-arg HTTPS_PROXY=$httpps --build-arg HTTP_PROXY=$httpp -t sco-soc:2.0 -f Dockerfile.soc .
fi

rm intel-graphics.key
