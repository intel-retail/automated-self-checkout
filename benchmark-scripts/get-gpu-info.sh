#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

HAS_FLEX_140=0
HAS_FLEX_170=0
HAS_ARC=0
GPU_NUM_140=0
GPU_NUM_170=0

has_flex_170=`lspci -d :56C0`
has_flex_140=`lspci -d :56C1`
has_arc=`lspci | grep -iE "5690|5691|5692|56A0|56A1|56A2|5693|5694|5695|5698|56A5|56A6|56B0|56B1|5696|5697|56A3|56A4|56B2|56B3"`

if [ -z "$has_flex_170" ] && [ -z "$has_flex_140" ] && [ -z "$has_arc" ] 
then
	echo "No discrete Intel GPUs found"
	return
fi
echo "GPU exists!"

if [ ! -z "$has_flex_140" ]
then
	HAS_FLEX_140=1
	GPU_NUM_140=`echo "$has_flex_140" | wc -l`
fi
if [ ! -z "$has_flex_170" ]
then
	HAS_FLEX_170=1
	GPU_NUM_170=`echo "$has_flex_170" | wc -l`
fi
if [ ! -z "$has_arc" ]
then
	HAS_ARC=1
fi

echo "HAS_FLEX_140=$HAS_FLEX_140, HAS_FLEX_170=$HAS_FLEX_170, HAS_ARC=$HAS_ARC, GPU_NUM_140=$GPU_NUM_140, GPU_NUM_170=$GPU_NUM_170"
