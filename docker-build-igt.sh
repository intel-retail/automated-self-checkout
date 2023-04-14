#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

if [ "$#" -eq 2 ]
then
	httpp=$1
	httpps=$2
elif [ "$#" -gt 0 ]
then
	echo "
	Builds not requiring network proxy
	 usage: ./docker-build-igt.sh 
	
	Optional: Builds requiring network proxy
	 usage: ./docker-build-igt.sh http_proxy_ip:http_proxy_port https_proxy_ip:https_proxy_port
	"
	exit 0
fi

# ./docker-build-igt.sh http://proxy-chain.intel.com:911 http://proxy-chain.intel.com:912

echo "Building igt HTTPS_PROXY=$httpps HTTP_PROXY=$httpp"
docker build --no-cache --build-arg HTTPS_PROXY=$httpps --build-arg HTTP_PROXY=$httpp -t igt:latest -f Dockerfile.igt .
