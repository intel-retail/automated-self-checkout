//*****************************************************************************
// Copyright 2021 Intel Corporation
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
#include <numeric>

#include "custom_node_interface.h"
#include "opencv_utils.hpp"
#include "utils.hpp"
#include "opencv2/opencv.hpp"

bool debugMode = false;

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

float boxiou_threshold = 0.3;
float iou_threshold = 0.3;

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

        // std::string imgname = "/tmp/results/classifyimage" + std::to_string(i) + ".jpg";
        // cv::imwrite(imgname.c_str(), originalImage);

        cv::Mat cropped = originalImage(box);
        cv::resize(cropped, image, targetShape);

        //  std::string imgname = "/tmp/results/classifyimage" + std::to_string(i) + ".jpg";
        //  cv::Mat tmp2;
        //  image.convertTo(tmp2, CV_8UC3);
        //  cv::imwrite(imgname.c_str(), tmp2); 

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

// YoloV8 PostProcessing

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

std::vector<size_t> nms(const std::vector<DetectedResult>& res, const float thresh, bool includeBoundaries=false, size_t keep_top_k=0) {
    if (keep_top_k == 0) {
        keep_top_k = 10; //res.size();
    }
    std::vector<float> areas(res.size());
    for (size_t i = 0; i < res.size(); ++i) {
        areas[i] = (float) (res[i].width - res[i].x + includeBoundaries) * (res[i].height - res[i].y + includeBoundaries);
    }
    std::vector<int> order(res.size());
    std::iota(order.begin(), order.end(), 0);
    std::sort(order.begin(), order.end(), [&res](int o1, int o2) { return res[o1].confidence > res[o2].confidence; });

    size_t ordersNum = 0;
    for (; ordersNum < order.size() && res[order[ordersNum]].confidence >= 0  && ordersNum < keep_top_k; ordersNum++);

    std::vector<size_t> keep;
    bool shouldContinue = true;
    for (size_t i = 0; shouldContinue && i < ordersNum; ++i) {
        int idx1 = order[i];
        if (idx1 >= 0) {
            keep.push_back(idx1);
            shouldContinue = false;
            for (size_t j = i + 1; j < ordersNum; ++j) {
                int idx2 = order[j];
                if (idx2 >= 0) {
                    shouldContinue = true;
                    float overlappingWidth = std::fminf(res[idx1].width, res[idx2].width) - std::fmaxf(res[idx1].x, res[idx2].x);
                    float overlappingHeight = std::fminf(res[idx1].height, res[idx2].height) - std::fmaxf(res[idx1].y, res[idx2].y);
                    float intersection = overlappingWidth > 0 && overlappingHeight > 0 ? overlappingWidth * overlappingHeight : 0;
                    float union_area = areas[idx1] + areas[idx2] - intersection;
                    if (0.0f == union_area || intersection / union_area > thresh) {
                        order[j] = -1;
                    }
                }
            }
        }
    }
    return keep;
}

std::vector<size_t> multiclass_nms(const std::vector<DetectedResult>& res, const float iou_threshold, bool includeBoundaries, size_t maxNum) {
    std::vector<DetectedResult> boxes_copy;
    boxes_copy.reserve(res.size());

    float max_coord = 0.f;
    for (const auto& box : res) {
        max_coord = std::max(max_coord, std::max((float)box.width, (float)box.height));
    }
    for (auto& box : res) {
        float offset = box.classId * max_coord;
        DetectedResult tmp;
        tmp.x = box.x + offset;
        tmp.y = box.y + offset;
        tmp.width = box.width + offset;
        tmp.height = box.height + offset;
        tmp.classId = box.classId;
        tmp.confidence = box.confidence;
        boxes_copy.emplace_back(tmp);
    }

    return nms(boxes_copy, iou_threshold, includeBoundaries, maxNum);
}


void postprocess(const float confidence_threshold, const int imageWidth, const int imageHeight, 
                 const uint64_t* output_shape, const void* voutputData, const uint32_t dimCount, 
                 std::vector<cv::Rect> &rects, std::vector<float> &scores)
{
    if (!voutputData || !output_shape) {
        // nothing to do
        return;
    }

    /* 
      https://github.com/openvinotoolkit/openvino_notebooks/blob/main/notebooks/230-yolov8-optimization/230-yolov8-object-detection.ipynb
      detection box has the [x, y, h, w, class_no_1, ..., class_no_80] format, where:
      (x, y) - raw coordinates of box center
      h, w - raw height and width of the box
      class_no_1, ..., class_no_80 - probability distribution over the classes.
    */

    std::vector<DetectedResult> detectedResults;
    size_t num_proposals = output_shape[2];
    std::vector<DetectedResult> boxes_with_class;
    std::vector<float> confidences;
    const float* const detections = (float*)(voutputData);
    for (size_t i = 0; i < num_proposals; ++i) {
        float confidence = 0.0f;
        size_t max_id = 0;
        constexpr size_t LABELS_START = 4;
        // get max confidence level in the 80 classes for this detection
        for (size_t j = LABELS_START; j < output_shape[1]; ++j) {
            if (detections[j * num_proposals + i] > confidence) {
                confidence = detections[j * num_proposals + i];
                max_id = j;
            }
        }
        // add the detection if the max confi. meets the threshold
        if (confidence > confidence_threshold) {
            DetectedResult obj;            
            obj.x = detections[0 * num_proposals + i] - detections[2 * num_proposals + i] / 2.0f;
            obj.y = detections[1 * num_proposals + i] - detections[3 * num_proposals + i] / 2.0f;
            obj.width = detections[0 * num_proposals + i] + detections[2 * num_proposals + i] / 2.0f;
            obj.height = detections[1 * num_proposals + i] + detections[3 * num_proposals + i] / 2.0f;
            obj.classId = max_id - LABELS_START;
            obj.confidence = confidence;

            boxes_with_class.emplace_back(obj);
            confidences.push_back(confidence);
        }
    }

    constexpr bool includeBoundaries = false;
    constexpr size_t keep_top_k = 30000;
    std::vector<size_t> keep;
    bool agnostic_nms = true;

    if (agnostic_nms) {
        keep = nms(boxes_with_class, boxiou_threshold, includeBoundaries, keep_top_k);
    } else {
        keep = multiclass_nms(boxes_with_class, boxiou_threshold, includeBoundaries, keep_top_k);
    }
    
    int padLeft = 15, padTop = 0; // adjust padding for optimal efficientnet inference
    float floatInputImgWidth = float(imageWidth),
          floatInputImgHeight = float(imageHeight),
          netInputWidth = floatInputImgWidth,
          netInputHeight = floatInputImgHeight,
          invertedScaleX = floatInputImgWidth / netInputWidth,
          invertedScaleY = floatInputImgHeight / netInputHeight;
    
    for (size_t idx : keep) {
        int x1 = std::clamp(
                    round((boxes_with_class[idx].x - padLeft) * invertedScaleX),
                    0.f,
                    floatInputImgWidth);
        int y1 = std::clamp(
                    round((boxes_with_class[idx].y - padTop) * invertedScaleY),
                    0.f,
                    floatInputImgHeight);
        int x2 = std::clamp(
                    round((boxes_with_class[idx].width + padLeft) * invertedScaleX) - x1,
                    0.f,
                    floatInputImgWidth - x1);
        int y2 = std::clamp(
                    round((boxes_with_class[idx].height + padTop) * invertedScaleY) - y1,
                    0.f,
                    floatInputImgHeight-y1); 
        
        rects.emplace_back(x1, y1, x2, y2);
        scores.emplace_back(confidences[idx]);
    }
}
// End of Yolov8 PostProcessing

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
    debugMode = get_string_parameter("debug", params, paramsCount) == "true";

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
    NODE_ASSERT(boxesTensor->precision == FP32, "boxes input is not FP32");

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
    (*info)[1].dimsCount = 3;
    (*info)[1].dims = (uint64_t*)malloc((*info)[1].dimsCount * sizeof(uint64_t));
    NODE_ASSERT(((*info)[1].dims) != nullptr, "malloc has failed");
    // 416x416    
    (*info)[1].dims[0] = 1;
    (*info)[1].dims[1] = 84;
    (*info)[1].dims[2] = 3549;

    // 512x512
    // (*info)[1].dims[0] = 1;
    // (*info)[1].dims[1] = 84;
    // (*info)[1].dims[2] = 5376;

    //640x640
    // (*info)[1].dims[0] = 1;
    // (*info)[1].dims[1] = 84;
    // (*info)[1].dims[2] = 8400;
    
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
