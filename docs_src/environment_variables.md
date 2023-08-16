When running docker-run.sh script, we support environment variables as input for container. Here is a list of environment variables and how you may apply it to docker-run.sh script as input

| Environment Variable   | Purpose                                                                 |
| -----------------------| ------------------------------------------------------------------------|
| STREAM_DENSITY_MODE=1  | for starting single container stream density testing                    |
| RENDER_MODE=1          | for displaying pipeline and overlay CV metadata                         |
| LOW_POWER=1            | for using GPU usage only based pipeline for Core platforms              |
| CPU_ONLY=1             | for overriding inference to be performed on CPU only                    |

More environment variables can be configured for advanced user in configs/dlstreamer/framework-pipelines/yolov5_pipeline/
    - yolov5-cpu.env for running pipeline in core system
    - yolov5-gpu.env for running pipeline in gpu or multi

these 2 files currently holds the default values. The above table lists environment variables you may input along with the docker-run.sh, the environment variable input to docker-run.sh will overwrite the value set in yolov5-cpu.env or yolov5-gpu.env as input to pipeline run.

Here is an example how to apply environment variable when call docker-run.sh to run pipeline:
```bash
CPU_ONLY=1 sudo -E ./docker-run.sh --workload dlstreamer --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0 --ocr_disabled --barc
ode_disabled
```