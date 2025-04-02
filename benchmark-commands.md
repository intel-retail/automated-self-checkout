# Benchmark Commands

You can use the following commands to run stream density benchmarks. The benchmark script will execute multiple concurrent pipelines while maintaining the target FPS, which defaults to 14.95. Once the FPS drops below this threshold, the script will report the maximum number of pipelines that can run simultaneously on the same machine.

You can check the results at performance-tools/benchmark-scripts/**cpu**/ folder for CPU only commands.

## CPU only

Run with Batch size 1 on CPU only

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-cpu.env BATCH_SIZE=1 RESULTS_DIR=cpu benchmark-stream-density
```

Run with Batch size 8 on CPU only

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-cpu.env BATCH_SIZE=8 RESULTS_DIR=cpubatch8 benchmark-stream-density
```

## GPU only

Run with Batch size 1 on GPU only

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-gpu.env BATCH_SIZE=1 RESULTS_DIR=gpu benchmark-stream-density 
```

Run with Batch size 8 on GPU only

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-gpu.env BATCH_SIZE=8 RESULTS_DIR=gpubatch8 benchmark-stream-density 
```

## dGPU only (GPU.1)

Run with Batch size 1 on dGPU only

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-dgpu.env BATCH_SIZE=1 RESULTS_DIR=dgpu benchmark-stream-density 
```

Run with Batch size 8 on dGPU only

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-dgpu.env BATCH_SIZE=8 RESULTS_DIR=dgpubatch8 benchmark-stream-density 
```

## NPU only

Run with Batch size 1 on NPU only

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-npu.env BATCH_SIZE=1 RESULTS_DIR=npu benchmark-stream-density 
```

Run with Batch size 8 on NPU only

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-npu.env BATCH_SIZE=8 RESULTS_DIR=npubatch8 benchmark-stream-density 
```

## Combination of CPU/GPU

Run with Yolov5 on CPU and Efficientnet on GPU Batch size 1

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/yolov5-cpu-class-gpu.env BATCH_SIZE=1 RESULTS_DIR=yolocpuclassgpu benchmark-stream-density 
```

Run with Yolov5 on CPU and Efficientnet on GPU Batch size 8

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/yolov5-cpu-class-gpu.env BATCH_SIZE=8 RESULTS_DIR=yolocpuclassgpubatch8 benchmark-stream-density 
```

Run with Yolov5 on GPU and Efficientnet on CPU Batch size 1

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/yolov5-gpu-class-cpu.env BATCH_SIZE=1 RESULTS_DIR=yologpuclasscpu benchmark-stream-density 
```

Run with Yolov5 on GPU and Efficientnet on CPU Batch size 8

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/yolov5-gpu-class-cpu.env BATCH_SIZE=8 RESULTS_DIR=yologpuclasscpubatch8 benchmark-stream-density 
```