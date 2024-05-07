# Performance Testing

The performance tools repository is included as a github submodule in this project. The performance tools enable you to test the pipeline system performance on various hardware. 

## Benchmark specific number of pipelines

You can launch a specific number of Automated Self Checkout containers using the PIPELINE_COUNT environment variable. Default is to launch One yolov5s_full.sh pipeline. You can override these values through Environment Variables.

```bash
make benchmark
```

```bash
make PIPELINE_COUNT=2 benchmark 
```

Environment variable overrides can also be added to the command

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh PIPELINE_COUNT=2 benchmark
```

Alternatively you can directly call the benchmark.py. This enables you to take advantage of all performance tools parameters. More details about the performance tools can be found [HERE](https://github.com/intel-retail/documentation/blob/main/docs_src/performance-tools/benchmark.md)

```bash
cd performance-tools/benchmark-scripts && python benchmark.py --compose_file ../../src/docker-compose.yml --pipeline 2
```

## Benchmark Stream Density

To test the maximum amount of Automated Self Checkout containers that can run on a system you can use the TARGET_FPS environment variable. Default is to find the container threshold over FPS over 14.95 with the yolov5s_full.sh pipeline. You can override these values through Environment Variables.

```bash
make benchmark-stream-density
```

```bash
make TARGET_FPS=13.5 benchmark-stream-density
```

Environment variable overrides can also be added to the command

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh TARGET_FPS=13.5 benchmark-stream-density
```

Alternatively you can directly call the benchmark.py. This enables you to take advantage of all performance tools parameters. More details about the performance tools can be found [HERE](https://github.com/intel-retail/documentation/blob/main/docs_src/performance-tools/benchmark.md)

```bash
cd performance-tools/benchmark-scripts && python benchmark.py --compose_file ../../src/docker-compose.yml --target_fps 14
```