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
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/barcode.hpp>
#include <iomanip>

class BarcodeProcessor
{

private:
    cv::barcode::BarcodeDetector barcodeDetector;
    cv::VideoCapture cap;    
    std::vector<cv::String> decoded_info;
    std::vector<cv::barcode::BarcodeType> decoded_type;
    std::vector<cv::Point> corners;

public:
    void decode(cv::Mat frame)
    {
        barcodeDetector.detectAndDecode(frame, decoded_info, decoded_type, corners);

        if (!corners.empty())
        {
            for (int i = 0; i < static_cast<int>(corners.size()); i += 4)
            {                
                if (decoded_info[i / 4].empty())
                {
                    this->drawBoundingBox(frame,corners[i], corners[i + 1], corners[i + 2], corners[i + 3], cv::Scalar(255, 0, 0));
                } // Barcode decoded
                else
                {
                    this->drawBoundingBox(frame,corners[i], corners[i + 1], corners[i + 2], corners[i + 3], cv::Scalar(0, 255, 255));
                    this->displayText(frame,decoded_type[i / 4] + ":  " + decoded_info[i / 4], corners[i]);
                }
            }
        }

    }

private:
    void drawBoundingBox(cv::Mat frame,const cv::Point &p1, const cv::Point &p2, const cv::Point &p3, const cv::Point &p4, const cv::Scalar &color)
    {
        cv::line(frame, p1, p2, color, 2);
        cv::line(frame, p2, p3, color, 2);
        cv::line(frame, p3, p4, color, 2);
        cv::line(frame, p4, p1, color, 2);
    }

    void displayText(cv::Mat frame,const std::string &text, const cv::Point &position)
    {
        cv::putText(frame, text, position, cv::FONT_HERSHEY_COMPLEX, 0.8, cv::Scalar(0, 0, 255));
        std::cout << text << std::endl;
    }
};