#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0

if [ -z "$model2022" ]
then
    echo "Please enter model result location."
    exit 1
fi

if [ -z "$modelNameFromList" ]
then
    echo "Please enter model name to download."
    exit 1
fi

docker run -u "$(id -u)":"$(id -g)" -v "$model2022":/models openvino/ubuntu20_dev:latest omz_downloader --name "$modelNameFromList" --output_dir /models
docker run -u "$(id -u)":"$(id -g)" -v "$model2022":/models:rw openvino/ubuntu20_dev:latest omz_converter --name "$modelNameFromList" --download_dir /models --output_dir /models

(
    # create folder 1 under each precision FP directory to hold the .bin and .xml files
    cd "$model2022"/intel || { echo "Error: folder \"intel\" was not created by converter."; exit 1; }
    for eachModel in */ ; do
        echo "$eachModel"
        (
            cd "$eachModel" || { echo "Error cd into $eachModel"; exit 1; }
            for FP_Dir in */ ; do
                echo "$FP_Dir"
                mkdir -p "$FP_Dir"1
                mv "$FP_Dir"*.bin "$FP_Dir"1
                mv "$FP_Dir"*.xml "$FP_Dir"1
            done
        )
    done
)

mv "$model2022"/intel/* "$model2022"/
rm -r "$model2022"/intel
