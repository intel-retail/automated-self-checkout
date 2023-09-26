# Docker Run Command Examples
docker run --network host --privileged --rm -v `pwd`/results:/app/results --name dev -p 8080:8080 grpc_go:dev

docker run --network host --privileged --rm -v `pwd`/results:/app/results --name dev -p 8080:8080 -it grpc_go:dev /bin/bash


docker run --rm -d -v $(pwd)/models:/models -p 9000:9000 openvino/model_server:latest --model_name resnet --model_path /models/resnet --port 9000 --layout NHWC:NCHW --plugin_config '{"PERFORMANCE_HINT":"LATENCY"}'

docker run --rm -d -v $(pwd)/models:/models -p 8001:8001 -p 9000:9000 --name ovms openvino/model_server:2022.3 --model_name yolov5 --model_path /models/yolov5ovms --rest_port 8001 --port 9000 --layout NHWC:NCHW --plugin_config '{"PERFORMANCE_HINT":"LATENCY"}'

./grpc-go -i rtsp://127.0.0.1:8554/camera_0 -u 127.0.0.1:9000