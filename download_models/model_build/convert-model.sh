#!/bin/bash

if [ "$1" == "--refresh" ]
then
	rm -R models/
	rm yolov8n*.xml
	rm yolov8n*.bin
fi

if [ -f models/yolov8n.onnx ] || [ -f yolov8n-int8-416.bin ]
then
	echo "--refresh required"
	exit 1
fi

python3 convert-model.py

if [ ! -f models/yolov8n.onnx ]
then
	echo "Model conversion failed  for onnx!"
	exit 1
fi

if [ ! -f models/yolov8n_openvino_model/yolov8n.bin ]
then
	echo "Model conversion failed for IR!"
	exit 1
fi

echo "OpenVINO FP32 yolov8n 416x416 creation successful!"
mv models/yolov8n_openvino_model/* .
mv yolov8n.xml yolov8n-fp32-416.xml 
mv yolov8n.bin yolov8n-fp32-416.bin

echo "OpenVINO INT8 quantization starting..."
python3 quantize-model.py
