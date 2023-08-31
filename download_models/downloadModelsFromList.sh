#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0

echo "start download from list models.lst"
omz_downloader --list models.lst
omz_converter --list models.lst

# create folder 1 under each precision FP directory to hold the .bin and .xml files
cd intel || { echo "Error: folder \"intel\" was not created by converter."; exit 1; }
for d in */ ; do
    echo "$d"
    (
        cd "$d" || { echo "Error cd into $d"; exit 1; }
        for FP_Dir in */ ; do
            echo "$FP_Dir"
            mkdir -p "$FP_Dir"1
            mv "$FP_Dir"*.bin "$FP_Dir"1
            mv "$FP_Dir"*.xml "$FP_Dir"1
        done
    )
    #TODO: remove below 3 lines when our model name updated to use - instead _
    newname=${d//[-]/_}
    echo "$newname"
    mv "$d" "$newname"
done

# move back to shared folder
cp -r /app/intel/* /2022/
