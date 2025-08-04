import cv2
import torch
from ultralytics import YOLO

# Initialize the YOLO model (make sure to download the YOLOv8 weights or any other YOLO model you prefer)
model = YOLO('yolov8n.pt').cuda()  # Move the model to CUDA device

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# Open the USB camera (0 is usually the default camera, change if you have multiple cameras)
cap = cv2.VideoCapture(0)

if not cap.isOpened():
    print("Error: Could not open video stream from USB camera.")
    exit()

def plot_detections(frame, results):
    for result in results:
        boxes = result.boxes
        for box in boxes:
            # Get the bounding box coordinates and the confidence score
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            confidence = box.conf[0]
            class_id = int(box.cls[0])

            # Get the label of the detected object
            label = model.names[class_id]

            # Draw the bounding box
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)

            # Draw the label and confidence score
            label_text = f"{label}: {confidence:.2f}"
            label_size, base_line = cv2.getTextSize(label_text, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
            top_left_corner = (x1, y1 - label_size[1] - base_line)
            bottom_right_corner = (x1 + label_size[0], y1)
            cv2.rectangle(frame, top_left_corner, bottom_right_corner, (0, 255, 0), cv2.FILLED)
            cv2.putText(frame, label_text, (x1, y1 - base_line), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1)

    return frame

frame_count = 0
process_every_n_frames = 2  # Change this value to skip more frames

while True:
    # Capture frame-by-frame
    ret, frame = cap.read()

    if not ret:
        print("Error: Could not read frame from camera.")
        break

    frame_count += 1
    if frame_count % process_every_n_frames != 0:
        continue

    img = torch.from_numpy(frame).to(device)
    img = img.permute(2, 0, 1).unsqueeze(0).float() / 255.0

    # Use the YOLO model to detect objects in the frame
    with torch.no_grad():  # No need to compute gradients during inference
        results = model(img.cuda())  # Move the input tensor to CUDA device

    # Draw the bounding boxes and labels on the frame using the custom plot function
    results = plot_detections(frame, results)

    # Display the resulting frame
    cv2.imshow('YOLO Detection', results)

    # Break the loop on 'q' key press
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# When everything done, release the capture
cap.release()
cv2.destroyAllWindows()
