import cv2
import json
from inference_sdk import InferenceHTTPClient, InferenceConfiguration

# ===== Configuration =====
VIDEO_SOURCE = "./data.mp4"  # Can be 0 for webcam
ROBOFLOW_MODEL = "theft-detection-using-computer-vision-with-data-augmentation/5"
CONFIDENCE = 0.5
IOU_THRESH = 0.5
OUTPUT_VIDEO = "./output.mp4"

# ===== Initialize Roboflow Client =====
try:
    with open('./appConfig.json') as f:
        api_key = json.load(f).get('ROBOFLOW_API_KEY', '')
except (FileNotFoundError, json.JSONDecodeError):
    print("Error loading config file")
    api_key = ''

client = InferenceHTTPClient(
    api_url="https://detect.roboflow.com",
    api_key=api_key
)

config = InferenceConfiguration(
    confidence_threshold=CONFIDENCE,
    iou_threshold=IOU_THRESH
)

def main():
    cap = cv2.VideoCapture(VIDEO_SOURCE)
    fps = int(cap.get(cv2.CAP_PROP_FPS))
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    # Define the codec and create VideoWriter object
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(OUTPUT_VIDEO, fourcc, fps, (width, height))

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # Convert frame to RGB (OpenCV uses BGR)
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Perform inference
        with client.use_configuration(config):
            try:
                result = client.infer(rgb_frame, model_id=ROBOFLOW_MODEL)
                theft_detected = False

                for pred in result["predictions"]:
                    confidence = pred['confidence']
                    class_name = pred['class']
                    
                    if confidence > 0.7:
                        theft_detected = True
                        box_color = (0, 0, 255)  # Red
                        text_color = (255, 255, 255)  # White
                    else:
                        box_color = (0, 255, 0)  # Green
                        text_color = (0, 0, 0)    # Black

                    x = int(pred["x"] - pred["width"]/2)
                    y = int(pred["y"] - pred["height"]/2)
                    cv2.rectangle(frame, (x, y), 
                                (x + int(pred["width"]), y + int(pred["height"])), 
                                box_color, 2)

                    label = f"{class_name} {confidence:.1%}"
                    cv2.putText(frame, label, (x, y-10), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, text_color, 2)

                if theft_detected:
                    alert_text = "THEFT DETECTED!"
                    text_scale = 2.5
                    thickness = 3
                    
                    (text_width, text_height), _ = cv2.getTextSize(
                        alert_text, cv2.FONT_HERSHEY_SIMPLEX, text_scale, thickness)
                    text_x = int((frame.shape[1] - text_width) / 2)
                    text_y = int(text_height + 20)
                    
                    cv2.rectangle(frame, (0, 0), (frame.shape[1], text_y + 20),
                                (0, 0, 255), -1)
                    cv2.putText(frame, alert_text, (text_x, text_y),
                            cv2.FONT_HERSHEY_SIMPLEX, text_scale, 
                            (255, 255, 255), thickness)

            except Exception as e:
                print(f"Inference error: {str(e)}")

        # Write the frame to the output video
        out.write(frame)

    cap.release()
    out.release()

if __name__ == "__main__":
    main()
