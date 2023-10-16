#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

for fld in $(find . -maxdepth 1 -type d)
do
  if [ $fld != "." ]; then
    (
      cd $fld; ls -l; make || true;
    )
  fi
  
done