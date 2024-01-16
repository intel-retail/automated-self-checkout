# Troubleshooting

Q: Why is the performance sometimes on CPU better than on GPU, when running pipeline benchmarking like stream density ?

A: The performance of pipeline benchmarking strongly depends on the models.  Specifically for `yolov5s` object detection, it is recommended to use the model precision FP32 when it is running on device `GPU`.  If supported, then you can change the model precision by going to the folder `configs/opencv-ovms/models/2022` from the root of project folder and editing the `base_path` for that particular model in the `config_template.json` file.  For example, you can change the the base_path of `FP16` to `FP32` assuming the precision `FP32` of the model yolov5s is available:  
        
        ```json
            ...
            "config": {
            "name": "yolov5s",
            "base_path": "/models/yolov5s/FP32-INT8",
            "layout": "NHWC:NCHW",
            ...
            }

        ```
