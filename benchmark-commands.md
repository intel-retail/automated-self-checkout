# Benchmark Commands

Run with CPU only Batch size 1

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-cpu.env BATCH_SIZE=1 RESULTS_DIR=cpu benchmark-stream-density
```

Run with CPU only Batch size 8

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-cpu.env BATCH_SIZE=1 RESULTS_DIR=cpubatch8 benchmark-stream-density
```

Run with GPU only Batch size 1

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-gpu.env BATCH_SIZE=1 RESULTS_DIR=gpu benchmark-stream-density 
```

Run with GPU only Batch size 8

```bash
make PIPELINE_SCRIPT=yolov5s_effnetb0.sh DEVICE_ENV=res/all-gpu.env BATCH_SIZE=8 RESULTS_DIR=gpubatch8 benchmark-stream-density 
```

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