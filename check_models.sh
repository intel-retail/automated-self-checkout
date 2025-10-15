#!/bin/bash

echo "Checking for existing models..."

# Check if models directory exists
if [ ! -d "./models" ]; then
    echo "Models directory does not exist. Need to download models."
    exit 0  # Need to download
fi

# Count XML files in models directory
XML_COUNT=$(find ./models -name "*.xml" | wc -l)
echo "Found $XML_COUNT XML model files"

# If 12 or more XML files exist, no need to download
if [ $XML_COUNT -ge 12 ]; then
    echo "Sufficient models exist ($XML_COUNT >= 12). Skipping download."
    exit 1  # Skip download
else
    echo "Insufficient models ($XML_COUNT < 12). Need to download."
    exit 0  # Need to download
fi