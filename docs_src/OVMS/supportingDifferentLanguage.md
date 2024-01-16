# Supporting Different Languages

For running OVMS as inferencing engine through grpc, these are the supported languages:

1. python
2. golang

## Sample Commands using the Camera Simulator
| Input source Type | Command                                                                                                     |          
|-------------------|-------------------------------------------------------------------------------------------------------------|
| Python | `PIPELINE_PROFILE="grpc_python" sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_1` |
| Golang | `PIPELINE_PROFILE="grpc_go" sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_1`     |


!!! Note
    Above example scripts are based on camera simulator for rtsp input source, before running them, please run the [camera simulator](../dev-tools/run_camera_simulator.md). If you used a different input source, fill in the appropriate value for `--inputsrc`.

