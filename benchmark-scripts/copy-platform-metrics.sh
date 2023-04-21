#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

LOG_DIRECTORY=$1

if [ -e ../results/r0.jsonl ]
then
  echo "Copying data for collection scripts...`pwd`"

  # when copying results from parent directory, add -p to preserve the timestamp of original files
  sudo cp -p -r ../results .
  sudo cp results/stream* $LOG_DIRECTORY || true
  sudo mv results/igt* $LOG_DIRECTORY || true
  sudo mv results/pipeline* $LOG_DIRECTORY
  sudo cp results/r* $LOG_DIRECTORY
  sudo python3 ./results_parser.py >> meta_summary.txt
  sudo mv meta_summary.txt $LOG_DIRECTORY
else
  echo "Warning no data found for collection!"
fi
