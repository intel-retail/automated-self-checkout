# Troubleshooting

Q: While running some pipeline benchmarking like stream density, why the performance may be worst running on GPU versus CPU?

A: The performance of pipeline benchmarking strongly depends on the models.  Specifically for `yolov5s` object detection, it is recommended to use the model precision FP32 when it is running on device `GPU`.  To change the model precision if supports, you can go to the folder `configs/opencv-ovms/models/2022` from the root of project folder and edit the `base_path` for that particular model in the `config_template.json` file.  For example, you can change the the base_path of `FP16` to `FP32` assuming the precision `FP32` of the model yolov5s is available: 
        
        ```json
            ...
            "config": {
            "name": "yolov5s",
            "base_path": "/models/yolov5s/FP32-INT8",
            "layout": "NHWC:NCHW",
            ...
            }

        ```
