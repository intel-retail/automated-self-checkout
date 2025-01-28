# Camera-Based Theft Detection System

A microservice application that detects theft in automated self-checkout scenarios using computer vision and the Roboflow API. The system processes video feeds and alerts when suspicious activities are detected with high confidence.

## Features

- Real-time theft detection using computer vision
- High-confidence alerts (>70% threshold)
- Video processing and annotation
- Output generation with visual indicators
- Integration with Roboflow's inference API

## Prerequisites

- Python 3.8+
- OpenCV
- Roboflow API key

## Installation

1. Clone the repository:
```
git clone [repository-url]
cd camera-theft
```

2. Create and activate virtual environment:
```
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
.\venv\Scripts\activate  # Windows
```

3. Install dependencies:
```
pip install -r requirements.txt
```

4. Configure API key:
Create `appConfig.json` with your Roboflow API key:
```
{
    "ROBOFLOW_API_KEY": "your-api-key-here"
}
```

## Usage

1. Place your input video as `data.mp4` in the project directory
2. Run the detection script:
```
python main.py
```
3. Check `output.mp4` for the processed video with annotations

## Configuration

Key parameters in `main.py`:
- `VIDEO_SOURCE`: Input video path or camera index
- `CONFIDENCE`: Detection confidence threshold (default: 0.5)
- `IOU_THRESH`: Intersection over Union threshold
- `OUTPUT_VIDEO`: Output file path

## Dependencies

- flask
- uvicorn
- python-multipart
- roboflow
- opencv-python
- pillow
- requests
- inference-sdk

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
