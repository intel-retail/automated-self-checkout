For running OVMS as inferencing engine through grpc, we are supporting multiple programming languages for your need. Here is the list of languages we are supporting:

1. python
2. golang

Here is the script example to start grpc-python using rtsp as inputsrc:
`PIPELINE_PROFILE="grpc_python" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0`

Here is the script example to start grpc-go using rtsp as inputsrc:
`PIPELINE_PROFILE="grpc_go" sudo -E ./run.sh --workload ovms --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0`


!!! Note
    Above example scripts are based on camera simulator for rtsp input source, before running them, please [run camera simulator](../run_camera_simulator.md). If you used pipeline scripts other than rtsp input source, then you don't need to run camera simulator.

