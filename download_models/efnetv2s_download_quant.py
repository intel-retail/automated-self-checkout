import os
import subprocess
from pathlib import Path
import urllib.request
import numpy as np
from openvino.runtime import Core, serialize
from nncf import Dataset, quantize
import shutil
import tensorflow_datasets as tfds
import tensorflow as tf
try:
    from nncf.quantization.advanced_parameters import AdvancedQuantizationParameters
except ImportError:
    # For newer NNCF versions
    try:
        from nncf.parameters import QuantizationParameters
        AdvancedQuantizationParameters = QuantizationParameters
    except ImportError:
        # If neither works, we'll handle it in the quantization function
        AdvancedQuantizationParameters = None


# Constants
MODEL_NAME = "efficientnet-v2-s"
PRECISIONS = ["FP32", "FP16"]

MOUNTED_MODELS_DIR = Path("models")
BASE_DIR = MOUNTED_MODELS_DIR / "object_classification" / MODEL_NAME
DOWNLOAD_DIR = BASE_DIR / "omz_download"
CACHE_DIR = BASE_DIR / "omz_cache"
OUTPUT_DIR = BASE_DIR
INT8_DIR = BASE_DIR / "INT8"

# Create necessary folders
INT8_DIR.mkdir(parents=True, exist_ok=True)

EXTRA_FILES = {
    "imagenet_2012.txt": "https://raw.githubusercontent.com/open-edge-platform/edge-ai-libraries/main/libraries/dl-streamer/samples/labels/imagenet_2012.txt",
    "preproc-aspect-ratio.json": "https://raw.githubusercontent.com/open-edge-platform/edge-ai-libraries/main/libraries/dl-streamer/samples/gstreamer/model_proc/public/preproc-aspect-ratio.json"
}

# Download model 
def run_downloader():
    model_dir = DOWNLOAD_DIR / "public" / MODEL_NAME
    if model_dir.exists() and any(model_dir.rglob("*")):
        print("[INFO] Model already downloaded. Skipping.")
        return
    elif any(CACHE_DIR.glob(f"{MODEL_NAME}*")):
        print("[INFO] Model already cached. Skipping.")
        return
    print("[INFO] Downloading model...")
    try:
        subprocess.run([
            "omz_downloader",
            "--name", MODEL_NAME,
            "--output_dir", str(DOWNLOAD_DIR),
            "--cache_dir", str(CACHE_DIR)
        ], check=True)
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Failed to download model: {e}")
        exit(1)

# Convert to OpenVINO IR 
def run_converter(precision):
    source_dir = OUTPUT_DIR / "public" / MODEL_NAME / precision
    target_dir = OUTPUT_DIR / precision
    ir_xml = target_dir / f"{MODEL_NAME}.xml"
    ir_bin = target_dir / f"{MODEL_NAME}.bin"

    if ir_xml.exists() and ir_bin.exists():
        print(f"[INFO] IR already in {precision}. Skipping.")
        return

    print(f"[INFO] Converting to IR ({precision})...")
    try:
        subprocess.run([
            "omz_converter",
            "--name", MODEL_NAME,
            "--precision", precision,
            "--download_dir", str(DOWNLOAD_DIR),
            "--output_dir", str(OUTPUT_DIR)
        ], check=True)
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Failed to convert model to {precision}: {e}")
        exit(1)

    target_dir.mkdir(parents=True, exist_ok=True)
    for file in source_dir.glob("*"):
        file.rename(target_dir / file.name)

    print(f"[DONE] Moved {precision} IR to: {target_dir.resolve()}")

# EfficientNet-V2-S preprocessing function
def preprocess_efficientnet_v2s(image):
    """
    Apply EfficientNet-V2-S specific preprocessing:
    - Resize to 384x384 (EfficientNet-V2-S input size)
    - Normalize with ImageNet statistics
    - Convert to CHW format
    """
    # Resize to model input size
    image = tf.image.resize(image, [384, 384], method='bilinear')
    
    # Convert to float32 and normalize to [0, 1]
    image = tf.cast(image, tf.float32) / 255.0
    
    # Apply ImageNet normalization (mean and std used during training)
    # ImageNet mean: [0.485, 0.456, 0.406], std: [0.229, 0.224, 0.225]
    mean = tf.constant([0.485, 0.456, 0.406])
    std = tf.constant([0.229, 0.224, 0.225])
    image = (image - mean) / std
    
    return image

# Load ImageNet validation set (preferred for quantization)
def load_imagenet_validation_images(input_key, limit=1000):
    """
    Load ImageNet validation images for calibration.
    Falls back to ImageNet-1k if imagenet2012 is not available.
    """
    print(f"[INFO] Loading ImageNet validation data for calibration...")
    
    # Try different ImageNet dataset names
    dataset_names = ['imagenet2012', 'imagenet_v2', 'imagenet_resized/32x32']
    dataset = None
    
    for name in dataset_names:
        try:
            print(f"[INFO] Trying to load dataset: {name}")
            if name == 'imagenet2012':
                dataset = tfds.load(name, split='validation', shuffle_files=True, 
                                  data_dir=None, download=True)
            else:
                dataset = tfds.load(name, split='test', shuffle_files=True, 
                                  data_dir=None, download=True)
            print(f"[INFO] Successfully loaded {name}")
            break
        except Exception as e:
            print(f"[WARNING] Could not load {name}: {e}")
            continue
    
    if dataset is None:
        print("[INFO] ImageNet not available, falling back to CIFAR-100...")
        return load_cifar100_images(input_key, limit)
    
    count = 0
    for example in tfds.as_numpy(dataset):
        if count >= limit:
            break
            
        img = example['image']
        
        # Skip images that are too small or have wrong dimensions
        if len(img.shape) != 3 or img.shape[2] != 3:
            continue
            
        # Apply EfficientNet-V2-S preprocessing
        img_tensor = tf.constant(img)
        img_processed = preprocess_efficientnet_v2s(img_tensor)
        
        # Convert to numpy and add batch dimension
        img_array = img_processed.numpy()
        img_array = img_array.transpose(2, 0, 1)  # CHW format
        img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension
        
        yield {input_key: img_array}
        count += 1
        
        if count % 100 == 0:
            print(f"[INFO] Processed {count}/{limit} calibration images...")

# Fallback: Load CIFAR-100 for calibration (more diverse than Caltech101)
def load_cifar100_images(input_key, limit=1000):
    """
    Load CIFAR-100 images as fallback calibration dataset.
    CIFAR-100 has 100 classes with more diversity than Caltech101.
    """
    print(f"[INFO] Loading CIFAR-100 data for calibration...")
    
    try:
        # Load both train and test splits for more diversity
        train_ds = tfds.load('cifar100', split='train', shuffle_files=True)
        test_ds = tfds.load('cifar100', split='test', shuffle_files=True)
        
        # Combine datasets
        combined_ds = train_ds.concatenate(test_ds)
        
        count = 0
        for example in tfds.as_numpy(combined_ds):
            if count >= limit:
                break
                
            img = example['image']
            
            # Apply EfficientNet-V2-S preprocessing
            img_tensor = tf.constant(img, dtype=tf.uint8)
            img_processed = preprocess_efficientnet_v2s(img_tensor)
            
            # Convert to numpy and add batch dimension
            img_array = img_processed.numpy()
            img_array = img_array.transpose(2, 0, 1)  # CHW format
            img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension
            
            yield {input_key: img_array}
            count += 1
            
            if count % 100 == 0:
                print(f"[INFO] Processed {count}/{limit} calibration images...")
                
    except Exception as e:
        print(f"[ERROR] Failed to load CIFAR-100: {e}")
        print("[INFO] Falling back to Caltech101...")
        return load_caltech101_images(input_key, limit)

# Improved Caltech101 loader with better preprocessing
def load_caltech101_images(input_key, limit=500):
    """
    Load Caltech101 images with improved preprocessing.
    """
    print(f"[INFO] Loading Caltech101 data for calibration...")
    
    ds = tfds.load('caltech101', split='train', shuffle_files=True)
    count = 0
    
    for example in tfds.as_numpy(ds):
        if count >= limit:
            break
            
        img = example['image']
        
        # Skip grayscale images or images with wrong dimensions
        if len(img.shape) != 3 or img.shape[2] != 3:
            continue
            
        # Apply EfficientNet-V2-S preprocessing
        img_tensor = tf.constant(img)
        img_processed = preprocess_efficientnet_v2s(img_tensor)
        
        # Convert to numpy and add batch dimension
        img_array = img_processed.numpy()
        img_array = img_array.transpose(2, 0, 1)  # CHW format
        img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension
        
        yield {input_key: img_array}
        count += 1
        
        if count % 100 == 0:
            print(f"[INFO] Processed {count}/{limit} calibration images...")

# Quantize FP32 model to INT8 with improved parameters
def quantize_model():
    fp32_path = OUTPUT_DIR / "FP32" / f"{MODEL_NAME}.xml"
    if not fp32_path.exists():
        raise FileNotFoundError(f"[ERROR] FP32 model not found at: {fp32_path}")

    int8_xml = INT8_DIR / f"{MODEL_NAME}-int8.xml"
    int8_bin = INT8_DIR / f"{MODEL_NAME}-int8.bin"
    if int8_xml.exists() and int8_bin.exists():
        print(f"[INFO] INT8 model already exists. Skipping quantization.")
        return fp32_path, OUTPUT_DIR / "FP16" / f"{MODEL_NAME}.xml", int8_xml

    print("[INFO] Loading model for quantization...")
    core = Core()
    model = core.read_model(fp32_path)
    input_key = model.inputs[0].get_any_name()
    print(f"Model input key: {input_key}, shape: {model.inputs[0].shape}")

    # Use ImageNet validation set (best choice for accuracy)
    # Optimized approach: 350 images for good accuracy with less time
    calibration_size = 350
    print(f"[INFO] Creating calibration dataset with {calibration_size} images...")
    
    dataset = Dataset(load_imagenet_validation_images(input_key, limit=calibration_size))
    
    print("[INFO] Starting quantization process...")
    
    # Modern NNCF quantization - try different approaches based on version
    try:
        # Method 1: Try with model_type parameter (newer NNCF versions)
        quantized_model = quantize(
            model=model,
            calibration_dataset=dataset,
            subset_size=calibration_size,
            model_type="transformer",  # or "transformer" for better accuracy
            fast_bias_correction=True  # Enable bias correction if available
        )
        print("[INFO] Quantization completed with advanced parameters")
    except Exception as e1:
        print(f"[INFO] Advanced method failed: {e1}")
        try:
            # Method 2: Basic quantization with just essential parameters
            quantized_model = quantize(
                model=model,
                calibration_dataset=dataset,
                subset_size=calibration_size
            )
            print("[INFO] Quantization completed with basic parameters")
        except Exception as e2:
            print(f"[ERROR] Quantization failed: {e2}")
            raise e2

    print("[INFO] Saving quantized model...")
    serialize(model=quantized_model, xml_path=str(int8_xml), bin_path=str(int8_bin))
    print(f"[DONE] INT8 model saved to: {INT8_DIR.resolve()}")

    return fp32_path, OUTPUT_DIR / "FP16" / f"{MODEL_NAME}.xml", int8_xml

# Download extra files
def download_extra_files():
    downloaded_paths = {}
    for filename, url in EXTRA_FILES.items():
        dest_path = INT8_DIR / filename
        if dest_path.exists():
            print(f"[INFO] {filename} already downloaded. Skipping.")
        else:
            print(f"[INFO] Downloading {filename}...")
            urllib.request.urlretrieve(url, dest_path)
            print(f"[DONE] Saved: {dest_path.resolve()}")
        downloaded_paths[filename] = dest_path.resolve()
    return downloaded_paths

# Cleanup
def clean_temp_dirs():
    folders_to_delete = [
        DOWNLOAD_DIR,
        CACHE_DIR,
        OUTPUT_DIR / "public"
    ]

    for folder in folders_to_delete:
        try:
            if folder.exists() and folder.is_dir():
                shutil.rmtree(folder)
        except Exception as e:
            print(f"[ERROR] Failed to delete {folder}: {e}")

# Main pipeline
if __name__ == "__main__":
    print("Starting improved quantization pipeline...")
    print("=" * 60)
    
    run_downloader()
    for p in PRECISIONS:
        run_converter(p)
    
    print("\n" + "=" * 60)
    print("Starting INT8 quantization with optimal settings...")
    fp32_xml, fp16_xml, int8_xml = quantize_model()
    
    print("\n" + "=" * 60)
    print("Downloading additional files...")
    extra_paths = download_extra_files()

    print("\n" + "=" * 60)
    print("FINAL MODEL PATHS:")
    print(f"  FP32: {fp32_xml}")
    print(f"  FP16: {fp16_xml}")
    print(f"  INT8: {int8_xml}")
    for name, path in extra_paths.items():
        print(f"  {name}: {path}")

    print("\nCleaning up temporary folders...")
    clean_temp_dirs()
    print("Pipeline completed successfully!")