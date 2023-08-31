For running OVMS as inferencing engine through grpc, we are supporting different models for your need. Here is the list of inferencing models we are currently supporting in python:

1. instance-segmentation-security-1040
2. bit_64

You can switch between them by editing the configuration file `configs/opencv-ovms/cmd_client/res/grpc_python/configuration.yaml`, uncomment `# PipelineInputArgs: "--model_name instance-segmentation-security-1040"` for supporting instance-segmentation-security-1040 and comment out rest; or you can uncomment `# PipelineInputArgs: "--model_name bit_64"` for supporting bit_64 and comment out rest.

Here is the configuration.yaml content, default to use `instance-segmentation-security-1040` model
```
OvmsClient:
  PipelineScript: run_grpc_kserv.sh
  PipelineInputArgs: "--model_name instance-segmentation-security-1040" # space delimited like we run the script in command and take those input arguments
  # PipelineInputArgs: "--model_name bit_64" # space delimited like we run the script in command and take those input arguments
  # PipelineInputArgs: "--model_name yolov5s" # space delimited like we run the script in command and take those input arguments

```