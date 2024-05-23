# Automated checkout using yolov8, text detection and recognition models with OpenVINO™

This Jupyter notebook demonstrates an automated checkout system that integrates object detection and text detection/recognition AI models. Utilizing YOLOv8 for object detection, the notebook efficiently identifies various items within a checkout frame, leveraging its robust and precise detection capabilities. To complement this, the notebook incorporates text detection and recognition within designated regions of interest. This combination allows for the extraction and interpretation of textual information—such as product labels and prices—from the detected items, facilitating a seamless and automated checkout process. The notebook is designed with detailed code explanations and visual outputs, making it accessible for users to understand and adapt the technology for various retail environments.

The tutorial consists of the following steps:
- Download the necessary models
- Convert the models to OpenVINO IR.
- Load models to OpenVINO engine 
- Perform object detection using yolov8, text detection and recognition. 
- Live demo

![automated checkout](automated.gif)

## Flow diagram

![diagram](diagram.jpg)

## Open in Google Colab

<a href="https://colab.research.google.com/github/antoniomtz/automated-self-checkout/blob/main/notebooks/automated-checkout.ipynb" target="_blank"><img src="https://camo.githubusercontent.com/f5e0d0538a9c2972b5d413e0ace04cecd8efd828d133133933dfffec282a4e1b/68747470733a2f2f636f6c61622e72657365617263682e676f6f676c652e636f6d2f6173736574732f636f6c61622d62616467652e737667" alt="Colab" data-canonical-src="https://colab.research.google.com/assets/colab-badge.svg" style="max-width: 100%;"></a>

## Installation

### Build docker image

```
$ docker build . -t automated-checkout
```

### Run docker container

```
docker run -it --device=/dev/dri --device=/dev/video0 --privileged --group-add=$(stat -c "%g" /dev/dri/render* | head -n 1) -p 8888:8888 automated-checkout
```

It will prompt the jupyter lab URL on the console, copy and paste it on your browser:

```
Or copy and paste one of these URLs:
        http://localhost:8888/lab?token=<token>
```

## Run it locally

Run the following commands to create a virtual env on your local system

Clone repo:
```
$ git clone https://github.com/intel-retail/automated-self-checkout.git
$ cd automated-self-checkout/notebooks
```

Create python virtual env:

```
python3 -m venv checkout
source checkout/bin/activate
pip install jupyterlab
```

Run jupyter notebook:

```
jupyter lab automated-checkout.ipynb
```

### TODO

- Include Classification model
- Barcode detection and encoding