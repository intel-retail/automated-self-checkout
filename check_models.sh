#!/bin/bash
# filepath: /home/intel/suryam/ASC/suryam789/automated-self-checkout/check_models.sh

set -o pipefail

echo "Checking for models required by pipeline script..."

# Define model paths
MODELS_DIR="./models"
YOLO_MODEL="$MODELS_DIR/object_detection/yolo11n/INT8/yolo11n.xml"
EFFNET_MODEL="$MODELS_DIR/object_classification/efficientnet-b0/INT8/efficientnet-b0-int8.xml"
FACE_DETECTION_MODEL="$MODELS_DIR/face_detection/FP16/face-detection-retail-0004.xml"
AGE_GENDER_MODEL="$MODELS_DIR/age_prediction/FP16/age-gender-recognition-retail-0013.xml"
TEXT_DETECTION_MODEL="$MODELS_DIR/text_detection/horizontal-text-detection-0001.xml"
TEXT_RECOGNITION_MODEL="$MODELS_DIR/text_recognition/text-recognition-resnet-fc.xml"

# Function to check if a model exists
check_model() {
    if [[ -f "$1" ]]; then
        echo "✓ Model found: $(basename $1)"
        return 0
    else
        echo "✗ Model missing: $(basename $1)"
        return 1
    fi
}

# Function to check models based on pipeline script
check_pipeline_models() {
    local pipeline_script="$1"
    local missing_models=0
    
    # Extract just the filename if full path is provided
    pipeline_script=$(basename "$pipeline_script")
    
    echo "Checking models for pipeline: $pipeline_script"
    
    case "$pipeline_script" in
        "yolo11n.sh")
            echo "Checking YOLO models..."
            check_model "$YOLO_MODEL" || ((missing_models++))
            ;;
            
        "yolo11n_full.sh")
            echo "Checking YOLO, EfficientNet, Text Detection, and Text Recognition models..."
            check_model "$YOLO_MODEL" || ((missing_models++))
            check_model "$EFFNET_MODEL" || ((missing_models++))
            check_model "$TEXT_DETECTION_MODEL" || ((missing_models++))
            check_model "$TEXT_RECOGNITION_MODEL" || ((missing_models++))
            ;;
            
        "yolo11n_effnetb0.sh")
            echo "Checking YOLO and EfficientNet models..."
            check_model "$YOLO_MODEL" || ((missing_models++))
            check_model "$EFFNET_MODEL" || ((missing_models++))
            ;;
            
        "obj_detection_age_prediction.sh")
            echo "Checking YOLO, EfficientNet, Face Detection, and Age/Gender Recognition models..."
            check_model "$YOLO_MODEL" || ((missing_models++))
            check_model "$EFFNET_MODEL" || ((missing_models++))
            check_model "$FACE_DETECTION_MODEL" || ((missing_models++))
            check_model "$AGE_GENDER_MODEL" || ((missing_models++))
            ;;
            
        *)
            echo "Unknown pipeline script: $pipeline_script"
            echo "Falling back to checking all models (12+ XML files)..."
            
            # Fallback to your original logic
            if [ ! -d "./models" ]; then
                echo "Models directory does not exist. Need to download models."
                exit 0  # Need to download
            fi
            
            XML_COUNT=$(find ./models -name "*.xml" | wc -l)
            echo "Found $XML_COUNT XML model files"
            
            if [ $XML_COUNT -ge 12 ]; then
                echo "Sufficient models exist ($XML_COUNT >= 12). Skipping download."
                exit 1  # Skip download
            else
                echo "Insufficient models ($XML_COUNT < 12). Need to download."
                exit 0  # Need to download
            fi
            ;;
    esac
    
    if [[ $missing_models -gt 0 ]]; then
        echo ""
        echo "Found $missing_models missing model(s). Need to download models."
        exit 0  # Need to download
    else
        echo ""
        echo "All required models are present! Skipping download."
        exit 1  # Skip download
    fi
}

# Main execution
if [[ -z "$PIPELINE_SCRIPT" ]]; then
    echo "PIPELINE_SCRIPT not set. Checking for general model availability..."
    
    # Fallback to your original logic
    if [ ! -d "./models" ]; then
        echo "Models directory does not exist. Need to download models."
        exit 0  # Need to download
    fi
    
    XML_COUNT=$(find ./models -name "*.xml" | wc -l)
    echo "Found $XML_COUNT XML model files"
    
    if [ $XML_COUNT -ge 12 ]; then
        echo "Sufficient models exist ($XML_COUNT >= 12). Skipping download."
        exit 1  # Skip download
    else
        echo "Insufficient models ($XML_COUNT < 12). Need to download."
        exit 0  # Need to download
    fi
else
    check_pipeline_models "$PIPELINE_SCRIPT"
fi































# #!/bin/bash

# echo "Checking for existing models..."

# # Check if models directory exists
# if [ ! -d "./models" ]; then
#     echo "Models directory does not exist. Need to download models."
#     exit 0  # Need to download
# fi

# # Count XML files in models directory
# XML_COUNT=$(find ./models -name "*.xml" | wc -l)
# echo "Found $XML_COUNT XML model files"

# # If 12 or more XML files exist, no need to download
# if [ $XML_COUNT -ge 12 ]; then
#     echo "Sufficient models exist ($XML_COUNT >= 12). Skipping download."
#     exit 1  # Skip download
# else
#     echo "Insufficient models ($XML_COUNT < 12). Need to download."
#     exit 0  # Need to download
# fi
