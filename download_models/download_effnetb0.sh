#!/bin/bash
# filepath: /home/intel/suryam/b0/B0_finalized/automated-self-checkout/download_models/download_effnetb0.sh

# Copyright (C) 2024 Intel Corporation.
# SPDX-License-Identifier: Apache-2.0

set -e

# Configuration
BASE_URL="https://raw.githubusercontent.com/dlstreamer/pipeline-zoo-models/refs/heads/main/storage/efficientnet-b0_INT8/FP16-INT8/"
MODEL_NAME="efficientnet-b0"
MODEL_DIR="${MODELS_DIR:-$(dirname "$(readlink -f "$0")")/../models}"
TARGET_DIR="$MODEL_DIR/object_classification/$MODEL_NAME/INT8"

# Create target directory
mkdir -p "$TARGET_DIR"

echo "Downloading EfficientNet-B0 INT8 models..."
echo "Target directory: $TARGET_DIR"

# Function to download file with source and target names
download_file() {
    local url="$1"
    local source_filename="$2"
    local target_filename="$3"
    local target_path="$TARGET_DIR/$target_filename"
    
    if [ -f "$target_path" ]; then
        echo "File already exists: $target_filename"
    else
        echo "Downloading: $source_filename -> $target_filename"
        wget "$url/$source_filename" -O "$target_path"
        echo "Downloaded: $target_filename"
    fi
}

# Download the model files from GitHub repository
# Note: GitHub repository may have different naming convention
download_file "$BASE_URL" "efficientnet-b0.xml" "efficientnet-b0-int8.xml"
download_file "$BASE_URL" "efficientnet-b0.bin" "efficientnet-b0-int8.bin"

# Also try alternative naming conventions that might exist on GitHub
if [ ! -f "$TARGET_DIR/efficientnet-b0-int8.xml" ]; then
    echo "Trying alternative filename: efficientnet-b0-int8.xml"
    download_file "$BASE_URL" "efficientnet-b0-int8.xml" "efficientnet-b0-int8.xml"
fi

if [ ! -f "$TARGET_DIR/efficientnet-b0-int8.bin" ]; then
    echo "Trying alternative filename: efficientnet-b0-int8.bin"
    download_file "$BASE_URL" "efficientnet-b0-int8.bin" "efficientnet-b0-int8.bin"
fi

# Download additional files that might be needed (based on pipeline usage)
echo "Checking for additional model files..."

# Try to download common additional files
additional_files=("imagenet_2012.txt" "preproc-aspect-ratio.json" "labels.txt")
for file in "${additional_files[@]}"; do
    if wget --spider "$BASE_URL/$file" 2>/dev/null; then
        download_file "$BASE_URL" "$file" "$file"
    else
        echo "Optional file not found on server: $file"
    fi
done

# Verify downloads
echo "Verifying downloaded files..."
for file in "$TARGET_DIR"/*; do
    if [ -f "$file" ]; then
        echo "✓ $(basename "$file") - $(du -h "$file" | cut -f1)"
    fi
done

echo "EfficientNet-B0 INT8 model download completed!"
echo "Models saved to: $TARGET_DIR"
echo ""
echo "Files available for pipeline:"
ls -la "$TARGET_DIR"