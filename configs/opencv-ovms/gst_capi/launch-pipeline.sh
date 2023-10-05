#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

# bash_cmd="./launch-pipeline.sh 
  # $PIPELINE_EXEC_PATH $INPUTSRC $USE_ONEVPL $RENDER_MODE $RENDER_PORTRAIT_MODE"
# 1 - pipeline path
# 2 - inputsrc
# 3 - use_onevpl
# 4 - enable rendering 
# 5 - RENDER_PORTRAIT_MODE
# 6 - codec_type (avc or hevc)

source ./get-media-codec.sh $2
echo "./$1 $2 $3 $4 $5 $is_avc"
./$1 $2 $3 $4 $5 $is_avc