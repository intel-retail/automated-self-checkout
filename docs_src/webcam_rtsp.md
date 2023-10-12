# Webcam to RTSP

When using /dev/video0 as input, only one container can use the webcam at the time.
If the intention is to run multiple pipelines at once using a webcam as the input, then, the solution is to covert the webcam to an RTSP path.

Run:

```bash
make webcam-rtsp
```

Then use the path *rtsp://127.0.0.1:8554/cam* as input