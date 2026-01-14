#!/bin/bash

if [ -n "$HTTP_PROXY" ]; then
    export http_proxy="$HTTP_PROXY"
fi
if [ -n "$HTTPS_PROXY" ]; then
    export https_proxy="$HTTPS_PROXY"
fi

VIDEO_SOURCE=${1:-""}
# Updated paths for organized model structure
FACE_MODEL="models/face_detection/FP16/face-detection-retail-0004.xml"
AGE_MODEL="models/age_prediction/FP16/age-gender-recognition-retail-0013.xml"
DEVICE="CPU"

set -e

mkdir -p models/face_detection/FP16
mkdir -p models/age_prediction/FP16

if [ -f "$FACE_MODEL" ] && [ -f "$AGE_MODEL" ]; then
    echo "Models already downloaded ✓"
    echo "Face detection model: $FACE_MODEL"
    echo "Age prediction model: $AGE_MODEL"
else
    echo "Downloading models using Open Model Zoo downloader..."
    
    echo "Downloading face detection model..."
    omz_downloader --name face-detection-retail-0004 --output_dir models/temp_face
     
    echo "Downloading age prediction model..."
    omz_downloader --name age-gender-recognition-retail-0013 --output_dir models/temp_age
    
    echo "Organizing face detection model..."
    if [ -d "models/temp_face/intel/face-detection-retail-0004" ]; then
        cp -r models/temp_face/intel/face-detection-retail-0004/* models/face_detection/
    fi
    
    echo "Organizing age prediction model..."
    if [ -d "models/temp_age/intel/age-gender-recognition-retail-0013" ]; then
        cp -r models/temp_age/intel/age-gender-recognition-retail-0013/* models/age_prediction/
    fi
    
    rm -rf models/temp_face models/temp_age
    
    echo "Listing downloaded models..."
    find models -name "*.xml" -o -name "*.bin" | sort
    
    echo "Model download and organization completed successfully!"
fi

echo "Downloading model-proc JSON files..."

wget -O models/age_prediction/age-gender-recognition-retail-0013.json \
    https://raw.githubusercontent.com/open-edge-platform/dlstreamer/refs/heads/master/samples/gstreamer/model_proc/intel/age-gender-recognition-retail-0013.json

wget -O models/face_detection/face-detection-retail-0004.json \
    https://raw.githubusercontent.com/open-edge-platform/dlstreamer/refs/heads/master/samples/gstreamer/model_proc/intel/face-detection-retail-0004.json

echo "Downloaded JSON files:"
ls models/age_prediction/*.json models/face_detection/*.json
