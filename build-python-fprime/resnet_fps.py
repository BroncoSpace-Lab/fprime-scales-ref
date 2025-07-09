import torch
from transformers import AutoImageProcessor, ResNetForImageClassification
from datasets import load_dataset
from PIL import Image
import numpy as np
import time

def load_model_and_processor(model_name="microsoft/resnet-152"):
    image_processor = AutoImageProcessor.from_pretrained(model_name)
    model = ResNetForImageClassification.from_pretrained(model_name)
    return model, image_processor

def process_image(image, image_processor):
    if isinstance(image, np.ndarray):
        image = Image.fromarray(image)
    inputs = image_processor(images=image, return_tensors="pt")
    return inputs

def classify_image(model, inputs):
    with torch.no_grad():
        outputs = model(**inputs)
    logits = outputs.logits
    predicted_class_idx = torch.argmax(logits, dim=-1).item()
    return predicted_class_idx

class FPSMeter:
    def __init__(self):
        self.start_time = None
        self.frame_count = 0
        
    def start(self):
        self.start_time = time.time()
        self.frame_count = 0
        
    def update(self):
        self.frame_count += 1
        
    def get_fps(self):
        if self.start_time is None:
            return 0.0
        elapsed_time = time.time() - self.start_time
        if elapsed_time == 0:
            return 0.0
        return self.frame_count / elapsed_time

def main(model_name="microsoft/resnet-152"):
    dataset = load_dataset("uoft-cs/cifar100", split="test")
    model, image_processor = load_model_and_processor(model_name)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = model.to(device)
    
    # Initialize FPS meter
    fps_meter = FPSMeter()
    
    # Warm-up run
    print("Warming up...")
    for _ in range(5):
        example = dataset[0]
        inputs = process_image(example["img"], image_processor)
        inputs = {k: v.to(device) for k, v in inputs.items()}
        classify_image(model, inputs)
    
    print(f"\nStarting inference on {device}...")
    fps_meter.start()  # Start timing
    
    total_frames = 10000  # Number of frames to process
    
    for i, example in enumerate(dataset):
        if i >= total_frames:
            break
            
        # Process and classify image
        inputs = process_image(example["img"], image_processor)
        inputs = {k: v.to(device) for k, v in inputs.items()}
        predicted_class_idx = classify_image(model, inputs)
        predicted_class = model.config.id2label[predicted_class_idx]
        #print(f"Image {i}, Predicted class: {predicted_class}")
        # Update FPS counter
        fps_meter.update()
        
        # Print progress and current FPS every 10 frames
        if (i + 1) % 10 == 0:
            current_fps = fps_meter.get_fps()
            print(f"\rProcessed {i+1}/{total_frames} images. Current FPS: {current_fps:.2f}", end="")
    
    # Final statistics
    final_fps = fps_meter.get_fps()
    print(f"\n\nFinal average FPS: {final_fps:.2f}")
    print(f"Total images processed: {total_frames}")
    print(f"Total time: {time.time() - fps_meter.start_time:.2f} seconds")

if __name__ == "__main__":
    main()