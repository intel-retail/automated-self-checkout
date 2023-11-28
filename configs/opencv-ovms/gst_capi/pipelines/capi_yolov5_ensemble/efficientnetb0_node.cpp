//*****************************************************************************
// Copyright 2023 Intel Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//*****************************************************************************
#include <iostream>
#include <string>
#include <vector>

#include "custom_node_interface.h"
#include "opencv_utils.hpp"
#include "utils.hpp"
#include "opencv2/opencv.hpp"

static constexpr const char* IMAGE_TENSOR_NAME = "images";
static constexpr const char* GEOMETRY_TENSOR_NAME = "boxes";
static constexpr const char* TEXT_IMAGES_TENSOR_NAME = "roi_images";
static constexpr const char* COORDINATES_TENSOR_NAME = "roi_coordinates";
static constexpr const char* CONFIDENCE_TENSOR_NAME = "confidence_levels";

typedef struct DetectedResult {
	int frameId;
	int x;
	int y;
	int width;
	int height;
	float confidence;
	int classId;
	char classText[1024];
} DetectedResult;

float boxiou_threshold = .4;
float iou_threshold = 0.4;

static bool copy_images_into_output(struct CustomNodeTensor* output, const std::vector<cv::Rect>& boxes, const cv::Mat& originalImage, int targetImageHeight, int targetImageWidth, const std::string& targetImageLayout, bool convertToGrayScale) {
    const uint64_t outputBatch = boxes.size();
    int channels = convertToGrayScale ? 1 : 3;

    uint64_t byteSize = sizeof(float) * targetImageHeight * targetImageWidth * channels * outputBatch;

    float* buffer = (float*)malloc(byteSize);
    NODE_ASSERT(buffer != nullptr, "malloc has failed");

    for (uint64_t i = 0; i < outputBatch; i++) {
        cv::Size targetShape(targetImageWidth, targetImageHeight);
        cv::Mat image;

        cv::Rect box = boxes[i];
        if (box.x < 0)
            box.x = 0;
        if (box.y < 0)
            box.y = 0;
        
        cv::Mat cropped = originalImage(box);
        
        cv::resize(cropped, image, targetShape);

        if (convertToGrayScale) {
            image = apply_grayscale(image);
        }

        if (targetImageLayout == "NCHW") {
            auto imgBuffer = reorder_to_nchw((float*)image.data, image.rows, image.cols, image.channels());
            std::memcpy(buffer + (i * channels * targetImageWidth * targetImageHeight), imgBuffer.data(), byteSize / outputBatch);
        } else {
             std::memcpy(buffer + (i * channels * targetImageWidth * targetImageHeight), image.data, byteSize / outputBatch);
        }
    }

    output->data = reinterpret_cast<uint8_t*>(buffer);
    output->dataBytes = byteSize;
    output->dimsCount = 5;
    output->dims = (uint64_t*)malloc(output->dimsCount * sizeof(uint64_t));
    NODE_ASSERT(output->dims != nullptr, "malloc has failed");
    output->dims[0] = outputBatch;
    output->dims[1] = 1;
    if (targetImageLayout == "NCHW") {
        output->dims[2] = channels;
        output->dims[3] = targetImageHeight;
        output->dims[4] = targetImageWidth;
    } else {
        output->dims[2] = targetImageHeight;
        output->dims[3] = targetImageWidth;
        output->dims[4] = channels;
    }
    output->precision = FP32;
    return true;
}

static bool copy_coordinates_into_output(struct CustomNodeTensor* output, const std::vector<cv::Rect>& boxes) {
    const uint64_t outputBatch = boxes.size();
    
    //printf("---------->NumberOfDets by coords %li\n", outputBatch);

    uint64_t byteSize = sizeof(int32_t) * 4 * outputBatch;

    int32_t* buffer = (int32_t*)malloc(byteSize);
    NODE_ASSERT(buffer != nullptr, "malloc has failed");

    for (uint64_t i = 0; i < outputBatch; i++) {
        int32_t entry[] = {
            boxes[i].x,
            boxes[i].y,
            boxes[i].width,
            boxes[i].height};

        std::memcpy(buffer + (i * 4), entry, byteSize / outputBatch);
    }
    output->data = reinterpret_cast<uint8_t*>(buffer);
    output->dataBytes = byteSize;
    output->dimsCount = 3;
    output->dims = (uint64_t*)malloc(output->dimsCount * sizeof(uint64_t));
    NODE_ASSERT(output->dims != nullptr, "malloc has failed");
    output->dims[0] = outputBatch;
    output->dims[1] = 1;
    output->dims[2] = 4;
    output->precision = I32;

    return true;
}

static bool copy_scores_into_output(struct CustomNodeTensor* output, const std::vector<float>& scores) {
    const uint64_t outputBatch = scores.size();
    //printf("Number of scores------------------>%li\n", outputBatch);
    uint64_t byteSize = sizeof(float) * outputBatch;

    float* buffer = (float*)malloc(byteSize);
    NODE_ASSERT(buffer != nullptr, "malloc has failed");
    std::memcpy(buffer, scores.data(), byteSize);

    output->data = reinterpret_cast<uint8_t*>(buffer);
    output->dataBytes = byteSize;
    output->dimsCount = 3;
    output->dims = (uint64_t*)malloc(output->dimsCount * sizeof(uint64_t));
    NODE_ASSERT(output->dims != nullptr, "malloc has failed");
    output->dims[0] = outputBatch;
    output->dims[1] = 1;
    output->dims[2] = 1;
    output->precision = FP32;
    return true;
}

int initialize(void** customNodeLibraryInternalManager, const struct CustomNodeParam* params, int paramsCount) {
    return 0;
}

int deinitialize(void* customNodeLibraryInternalManager) {
    return 0;
}

// YoloV5 PostProcessing

// Anchors by region/output layer
const float anchors_52[6] = {
    10.0,
    13.0,
    16.0,
    30.0,
    33.0,
    23.0
};

const float anchors_26[6] = {
    30.0,
    61.0,
    62.0,
    45.0,
    59.0,
    119.0
};

const float anchors_13[6] = {
    116.0,
    90.0,
    156.0,
    198.0,
    373.0,
    326.0
};

const std::string labels[80] = {
    "person",
    "bicycle",
    "car",
    "motorbike",
    "aeroplane",
    "bus",
    "train",
    "truck",
    "boat",
    "traffic light",
    "fire hydrant",
    "stop sign",
    "parking meter",
    "bench",
    "bird",
    "cat",
    "dog",
    "horse",
    "sheep",
    "cow",
    "elephant",
    "bear",
    "zebra",
    "giraffe",
    "backpack",
    "umbrella",
    "handbag",
    "tie",
    "suitcase",
    "frisbee",
    "skis",
    "snowboard",
    "sports ball",
    "kite",
    "baseball bat",
    "baseball glove",
    "skateboard",
    "surfboard",
    "tennis racket",
    "bottle",
    "wine glass",
    "cup",
    "fork",
    "knife",
    "spoon",
    "bowl",
    "banana",
    "apple",
    "sandwich",
    "orange",
    "broccoli",
    "carrot",
    "hot dog",
    "pizza",
    "donut",
    "cake",
    "chair",
    "sofa",
    "pottedplant",
    "bed",
    "diningtable",
    "toilet",
    "tvmonitor",
    "laptop",
    "mouse",
    "remote",
    "keyboard",
    "cell phone",
    "microwave",
    "oven",
    "toaster",
    "sink",
    "refrigerator",
    "book",
    "clock",
    "vase",
    "scissors",
    "teddy bear",
    "hair drier",
    "toothbrush"
};

int calculateEntryIndex(int totalCells, int lcoords, size_t lclasses, int location, int entry) {
    int n = location / totalCells;
    int loc = location % totalCells;
    return (n * (lcoords + lclasses) + entry) * totalCells + loc;
}

static inline float sigmoid(float x) {
    return 1.f / (1.f + std::exp(-x));
}

double intersectionOverUnion(const DetectedResult& o1, const DetectedResult& o2) {
    double overlappingWidth = std::fmin(o1.x + o1.width, o2.x + o2.width) - std::fmax(o1.x, o2.x);
    double overlappingHeight = std::fmin(o1.y + o1.height, o2.y + o2.height) - std::fmax(o1.y, o2.y);
    double intersectionArea = (overlappingWidth < 0 || overlappingHeight < 0) ? 0 : overlappingHeight * overlappingWidth;
    double unionArea = o1.width * o1.height + o2.width * o2.height - intersectionArea;
    return intersectionArea / unionArea;
}

// IOU postproc filter
void postprocess(std::vector<DetectedResult> &detectedResults,
                 std::vector<cv::Rect> &rects, std::vector<float> &scores)
{
    bool useAdvancedPostprocessing = false;

    if (useAdvancedPostprocessing) {
        // Advanced postprocessing
        // Checking IOU threshold conformance
        // For every i-th object we're finding all objects it intersects with, and comparing confidence
        // If i-th object has greater confidence than all others, we include it into result
        for (const auto& obj1 : detectedResults) {
            bool isGoodResult = true;
            for (const auto& obj2 : detectedResults) {
                if (obj1.classId == obj2.classId && obj1.confidence < obj2.confidence &&
                    intersectionOverUnion(obj1, obj2) >= boxiou_threshold) {  // if obj1 is the same as obj2, condition
                                                                            // expression will evaluate to false anyway
                    isGoodResult = false;
                    break;
                }
            }
            if (isGoodResult) {
                rects.emplace_back(
                obj1.x, 
                obj1.y, 
                obj1.width, 
                obj1.height);
                scores.emplace_back(obj1.confidence);
            }
        }
    } else {
        // Classic postprocessing
        std::sort(detectedResults.begin(), detectedResults.end(), [](const DetectedResult& x, const DetectedResult& y) {
            return x.confidence > y.confidence;
        });
        for (size_t i = 0; i < detectedResults.size(); ++i) {
            if (detectedResults[i].confidence == 0)
                continue;
            for (size_t j = i + 1; j < detectedResults.size(); ++j)
                if (intersectionOverUnion(detectedResults[i], detectedResults[j]) >= boxiou_threshold)
                    detectedResults[j].confidence = 0;
            
            rects.emplace_back(
                detectedResults[i].x, 
                detectedResults[i].y, 
                detectedResults[i].width, 
                detectedResults[i].height);
            scores.emplace_back(detectedResults[i].confidence);
        } //end for
    } // end if
} // end postprocess IOU filter


void postprocess(const float confidence_threshold, const int imageWidth, const int imageHeight, 
                 const uint64_t* output_shape, const void* voutputData, const uint32_t dimCount, 
                 std::vector<cv::Rect> &rects, std::vector<float> &scores)
{
    if (!voutputData || !output_shape) {
        // nothing to do
        return;
    }

    std::vector<DetectedResult> detectedResults;

    const int regionCoordsCount  = dimCount;
    const int sideH = 13; //output_shape[2]; // NCHW
    const int sideW = 13; //output_shape[3]; // NCHW
    const int regionNum = 3;
    
    const int scaleH = 416; 
    const int scaleW = 416; 

    auto entriesNum = sideW * sideH;
    const float* outData = reinterpret_cast<const float*>(voutputData);
    int original_im_w = imageWidth;
    int original_im_h = imageHeight;
    size_t classes = 80; // from yolo dataset     

    auto postprocessRawData = sigmoid; //sigmoid or linear

    for (int i = 0; i < entriesNum; ++i) {
        int row = i / sideW;
        int col = i % sideW;

        for (int n = 0; n < regionNum; ++n) {

            int obj_index = calculateEntryIndex(entriesNum,  regionCoordsCount, classes + 1 /* + confidence byte */, n * entriesNum + i,regionCoordsCount);
            int box_index = calculateEntryIndex(entriesNum, regionCoordsCount, classes + 1, n * entriesNum + i, 0);
            float scale = postprocessRawData(outData[obj_index]);

            if (scale >= confidence_threshold) {
                float x, y,height,width;
                x = static_cast<float>((col + postprocessRawData(outData[box_index + 0 * entriesNum])) / sideW * original_im_w);
                y = static_cast<float>((row + postprocessRawData(outData[box_index + 1 * entriesNum])) / sideH * original_im_h);
                height = static_cast<float>(std::pow(2*postprocessRawData(outData[box_index + 3 * entriesNum]),2) * anchors_13[2 * n + 1] * original_im_h / scaleH  );
                width = static_cast<float>(std::pow(2*postprocessRawData(outData[box_index + 2 * entriesNum]),2) * anchors_13[2 * n] * original_im_w / scaleW  );

                DetectedResult obj;
                
                obj.x = std::clamp(x - width / 2, 0.f, static_cast<float>(original_im_w));
                obj.y = std::clamp(y - height / 2, 0.f, static_cast<float>(original_im_h));
                obj.width = std::clamp(width, 0.f, static_cast<float>(original_im_w - obj.x));
                obj.height = std::clamp(height, 0.f, static_cast<float>(original_im_h - obj.y));
                
                for (size_t j = 0; j < classes; ++j) {
                    int class_index = calculateEntryIndex(entriesNum, regionCoordsCount, classes + 1, n * entriesNum + i, regionCoordsCount + 1 + j);
                    float prob = scale * postprocessRawData(outData[class_index]);

                    if (prob >= confidence_threshold) {                        
                        obj.confidence = prob;
                        detectedResults.push_back(obj);
                    }
                }
            } // end else
        } // end for
    } // end for

    postprocess(detectedResults, rects, scores);
}
// End of Yolov5 PostProcessing

int execute(const struct CustomNodeTensor* inputs, int inputsCount, struct CustomNodeTensor** outputs, int* outputsCount, const struct CustomNodeParam* params, int paramsCount, void* customNodeLibraryInternalManager) {

    // Parameters reading
    int originalImageHeight = get_int_parameter("original_image_height", params, paramsCount, -1);
    int originalImageWidth = get_int_parameter("original_image_width", params, paramsCount, -1);
    NODE_ASSERT(originalImageHeight > 0, "original image height must be larger than 0");
    NODE_ASSERT(originalImageWidth > 0, "original image width must be larger than 0");
    int targetImageHeight = get_int_parameter("target_image_height", params, paramsCount, -1);
    int targetImageWidth = get_int_parameter("target_image_width", params, paramsCount, -1);
    NODE_ASSERT(targetImageHeight > 0, "target image height must be larger than 0");
    NODE_ASSERT(targetImageWidth > 0, "target image width must be larger than 0");
    std::string originalImageLayout = get_string_parameter("original_image_layout", params, paramsCount, "NCHW");
    NODE_ASSERT(originalImageLayout == "NCHW" || originalImageLayout == "NHWC", "original image layout must be NCHW or NHWC");
    std::string targetImageLayout = get_string_parameter("target_image_layout", params, paramsCount, "NCHW");
    NODE_ASSERT(targetImageLayout == "NCHW" || targetImageLayout == "NHWC", "target image layout must be NCHW or NHWC");
    bool convertToGrayScale = get_string_parameter("convert_to_gray_scale", params, paramsCount) == "true";
    float confidenceThreshold = get_float_parameter("confidence_threshold", params, paramsCount, -1.0);
    NODE_ASSERT(confidenceThreshold >= 0 && confidenceThreshold <= 1.0, "confidence threshold must be in 0-1 range");
    uint64_t maxOutputBatch = get_int_parameter("max_output_batch", params, paramsCount, 100);
    NODE_ASSERT(maxOutputBatch > 0, "max output batch must be larger than 0");
    bool debugMode = get_string_parameter("debug", params, paramsCount) == "true";

    const CustomNodeTensor* imageTensor = nullptr;
    const CustomNodeTensor* boxesTensor = nullptr;

    for (int i = 0; i < inputsCount; i++) {
        if (std::strcmp(inputs[i].name, IMAGE_TENSOR_NAME) == 0) {
            imageTensor = &(inputs[i]);
        } else if (std::strcmp(inputs[i].name, GEOMETRY_TENSOR_NAME) == 0) {
            boxesTensor = &(inputs[i]);
        } else {
            std::cout << "Unrecognized input: " << inputs[i].name << std::endl;
            return 1;
        }
    }

    NODE_ASSERT(imageTensor != nullptr, "Missing input image");
    NODE_ASSERT(boxesTensor != nullptr, "Missing input boxes");
    NODE_ASSERT(imageTensor->precision == FP32, "image input is not FP32");
    NODE_ASSERT(boxesTensor->precision == FP32, "image input is not FP32");

    NODE_ASSERT(imageTensor->dimsCount == 4, "input image shape must have 4 dimensions");
    NODE_ASSERT(imageTensor->dims[0] == 1, "input image batch must be 1");
    uint64_t _imageHeight = imageTensor->dims[originalImageLayout == "NCHW" ? 2 : 1];
    uint64_t _imageWidth = imageTensor->dims[originalImageLayout == "NCHW" ? 3 : 2];
    NODE_ASSERT(_imageHeight <= static_cast<uint64_t>(std::numeric_limits<int>::max()), "image height is too large");
    NODE_ASSERT(_imageWidth <= static_cast<uint64_t>(std::numeric_limits<int>::max()), "image width is too large");
    int imageHeight = static_cast<int>(_imageHeight);
    int imageWidth = static_cast<int>(_imageWidth);

    if (debugMode) {
        std::cout << "Processing input tensor image resolution: " << cv::Size(imageHeight, imageWidth) << "; expected resolution: " << cv::Size(originalImageHeight, originalImageWidth) << std::endl;
    }

    NODE_ASSERT(imageHeight == originalImageHeight, "original image size parameter differs from original image tensor size");
    NODE_ASSERT(imageWidth == originalImageWidth, "original image size parameter differs from original image tensor size");

    cv::Mat image;
    if (originalImageLayout == "NHWC") {
        image = nhwc_to_mat(imageTensor);
    } else {
        image = nchw_to_mat(imageTensor);
    }

    NODE_ASSERT(image.cols == imageWidth, "Mat generation failed");
    NODE_ASSERT(image.rows == imageHeight, "Mat generation failed");

    std::vector<cv::Rect> rects;
    std::vector<float> scores;  
    postprocess(confidenceThreshold, originalImageWidth, originalImageHeight, boxesTensor->dims, boxesTensor->data, boxesTensor->dimsCount, rects, scores);

    NODE_ASSERT(rects.size() == scores.size(), "rects and scores are not equal length");
    if (rects.size() > maxOutputBatch) {
        rects.resize(maxOutputBatch);
        scores.resize(maxOutputBatch);
    }

    if (debugMode)
        std::cout << "Total findings: " << rects.size() << std::endl;

    *outputsCount = 3; // pipeline outputs for efficientnetb0_extractor e.g. roi_images, roi_coordinates, confidence_levels
    *outputs = (struct CustomNodeTensor*)malloc(*outputsCount * sizeof(CustomNodeTensor));

    NODE_ASSERT((*outputs) != nullptr, "malloc has failed");
    CustomNodeTensor& textImagesTensor = (*outputs)[0];
    textImagesTensor.name = TEXT_IMAGES_TENSOR_NAME;
 
    if (!copy_images_into_output(&textImagesTensor, rects, image, targetImageHeight, targetImageWidth, targetImageLayout, convertToGrayScale)) {
        free(*outputs);
        return 1;
    }

    CustomNodeTensor& coordinatesTensor = (*outputs)[1];
    coordinatesTensor.name = COORDINATES_TENSOR_NAME;
    if (!copy_coordinates_into_output(&coordinatesTensor, rects)) {
        free(*outputs);
        cleanup(textImagesTensor);
        return 1;
    }


    CustomNodeTensor& confidenceTensor = (*outputs)[2];
    confidenceTensor.name = CONFIDENCE_TENSOR_NAME;
    if (!copy_scores_into_output(&confidenceTensor, scores)) {
        free(*outputs);
        cleanup(textImagesTensor);
        cleanup(coordinatesTensor);
        return 1;
    }
    
    return 0;
}

int getInputsInfo(struct CustomNodeTensorInfo** info, int* infoCount, const struct CustomNodeParam* params, int paramsCount, void* customNodeLibraryInternalManager) {
    int originalImageHeight = get_int_parameter("original_image_height", params, paramsCount, -1);
    int originalImageWidth = get_int_parameter("original_image_width", params, paramsCount, -1);
    NODE_ASSERT(originalImageHeight > 0, "original image height must be larger than 0");
    NODE_ASSERT(originalImageWidth > 0, "original image width must be larger than 0");
    std::string originalImageLayout = get_string_parameter("original_image_layout", params, paramsCount, "NCHW");
    NODE_ASSERT(originalImageLayout == "NCHW" || originalImageLayout == "NHWC", "original image layout must be NCHW or NHWC");

    *infoCount = 2;
    *info = (struct CustomNodeTensorInfo*)malloc(*infoCount * sizeof(struct CustomNodeTensorInfo));
    NODE_ASSERT((*info) != nullptr, "malloc has failed");

    (*info)[0].name = IMAGE_TENSOR_NAME;
    (*info)[0].dimsCount = 4;
    (*info)[0].dims = (uint64_t*)malloc((*info)->dimsCount * sizeof(uint64_t));
    NODE_ASSERT(((*info)[0].dims) != nullptr, "malloc has failed");
    (*info)[0].dims[0] = 1;
    if (originalImageLayout == "NCHW") {
        (*info)[0].dims[1] = 3;
        (*info)[0].dims[2] = originalImageHeight;
        (*info)[0].dims[3] = originalImageWidth;
    } else {
        (*info)[0].dims[1] = originalImageHeight;
        (*info)[0].dims[2] = originalImageWidth;
        (*info)[0].dims[3] = 3;
    }
    (*info)[0].precision = FP32;

    (*info)[1].name = GEOMETRY_TENSOR_NAME;
    (*info)[1].dimsCount = 4;
    (*info)[1].dims = (uint64_t*)malloc((*info)[1].dimsCount * sizeof(uint64_t));
    NODE_ASSERT(((*info)[1].dims) != nullptr, "malloc has failed");
    (*info)[1].dims[0] = 1;
    (*info)[1].dims[1] = 255;
    (*info)[1].dims[2] = 13;
    (*info)[1].dims[3] = 13;
    (*info)[1].precision = FP32;
    return 0;
}

int getOutputsInfo(struct CustomNodeTensorInfo** info, int* infoCount, const struct CustomNodeParam* params, int paramsCount, void* customNodeLibraryInternalManager) {
    int targetImageHeight = get_int_parameter("target_image_height", params, paramsCount, -1);
    int targetImageWidth = get_int_parameter("target_image_width", params, paramsCount, -1);
    NODE_ASSERT(targetImageHeight > 0, "target image height must be larger than 0");
    NODE_ASSERT(targetImageWidth > 0, "target image width must be larger than 0");
    std::string targetImageLayout = get_string_parameter("target_image_layout", params, paramsCount, "NCHW");
    NODE_ASSERT(targetImageLayout == "NCHW" || targetImageLayout == "NHWC", "target image layout must be NCHW or NHWC");
    bool convertToGrayScale = get_string_parameter("convert_to_gray_scale", params, paramsCount) == "true";

    *infoCount = 3;
    *info = (struct CustomNodeTensorInfo*)malloc(*infoCount * sizeof(struct CustomNodeTensorInfo));
    NODE_ASSERT((*info) != nullptr, "malloc has failed");

    (*info)[0].name = TEXT_IMAGES_TENSOR_NAME;
    (*info)[0].dimsCount = 5;
    (*info)[0].dims = (uint64_t*)malloc((*info)->dimsCount * sizeof(uint64_t));
    NODE_ASSERT(((*info)[0].dims) != nullptr, "malloc has failed");
    (*info)[0].dims[0] = 0;
    (*info)[0].dims[1] = 1;
    if (targetImageLayout == "NCHW") {
        (*info)[0].dims[2] = convertToGrayScale ? 1 : 3;
        (*info)[0].dims[3] = targetImageHeight;
        (*info)[0].dims[4] = targetImageWidth;
    } else {
        (*info)[0].dims[2] = targetImageHeight;
        (*info)[0].dims[3] = targetImageWidth;
        (*info)[0].dims[4] = convertToGrayScale ? 1 : 3;
    }
    (*info)[0].precision = FP32;

    (*info)[1].name = COORDINATES_TENSOR_NAME;
    (*info)[1].dimsCount = 3;
    (*info)[1].dims = (uint64_t*)malloc((*info)->dimsCount * sizeof(uint64_t));
    NODE_ASSERT(((*info)[1].dims) != nullptr, "malloc has failed");
    (*info)[1].dims[0] = 0;
    (*info)[1].dims[1] = 1;
    (*info)[1].dims[2] = 4;
    (*info)[1].precision = I32;

    (*info)[2].name = CONFIDENCE_TENSOR_NAME;
    (*info)[2].dimsCount = 3;
    (*info)[2].dims = (uint64_t*)malloc((*info)->dimsCount * sizeof(uint64_t));
    NODE_ASSERT(((*info)[2].dims) != nullptr, "malloc has failed");
    (*info)[2].dims[0] = 0;
    (*info)[2].dims[1] = 1;
    (*info)[2].dims[2] = 1;
    (*info)[2].precision = FP32;

    return 0;
}

int release(void* ptr, void* customNodeLibraryInternalManager) {
    free(ptr);
    return 0;
}
