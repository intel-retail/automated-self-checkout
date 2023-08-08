#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

import os

def new_file_name(file):
    return file.replace("_template", "")


if __name__ == '__main__':
    file_to_prepare = "config_template.json"
    path_to_config = "/configFiles/"

    # Get the device env. Default to CPU
    target_device = os.environ.get("DEVICE", "CPU")

    # Open template for modification
    with open(os.path.join(path_to_config, file_to_prepare), "r") as template:
        new_file_path = os.path.join(path_to_config, new_file_name(file_to_prepare))

        # Open final config file for writing
        with open(new_file_path, "w+") as config_file:
            for line in template:
                # Replace target device with env $DEVICE
                if "{target_device}" in line:
                    line = line.replace("{target_device}", target_device)
                    print(line)
                config_file.write(line)