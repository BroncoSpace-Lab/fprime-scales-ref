import torch
from transformers import AutoImageProcessor, ResNetForImageClassification
from datasets import load_dataset
from PIL import Image
import os
import numpy as np
import time
from collections import deque

class FPSCounter:
    def __init__(self, window_size=30):
        self.frame_times = deque(maxlen=window_size)
        self.last_time = time.time()
    
    def update(self):
        current_time = time.time()
        self.frame_times.append(current_time - self.last_time)
        self.last_time = current_time
    
    def get_fps(self):
        if not self.frame_times:
            return 0
        avg_time = sum(self.frame_times) / len(self.frame_times)
        return 1 / avg_time if avg_time > 0 else 0

def load_model_and_processor(model_name="microsoft/resnet-152"):
    image_processor = AutoImageProcessor.from_pretrained(model_name)
    model = ResNetForImageClassification.from_pretrained(model_name)
    return model, image_processor

def process_image(image, image_processor):
    if isinstance(image,np.ndarray):
         image = Image.fromarray(image)
    inputs = image_processor(images=image, return_tensors="pt")
    return inputs

def classify_image(model, inputs):
    with torch.no_grad():
        outputs = model(**inputs)
    logits = outputs.logits
    predicted_class_idx = torch.argmax(logits, dim=-1).item()
    return predicted_class_idx

def main(folder_path, model_name="microsoft/resnet-152"):
    if folder_path is None:
        folder_path = "uoft-cs/cifar100"
    dataset = load_dataset(folder_path,split="test")
    model, image_processor = load_model_and_processor(model_name)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = model.to(device)

    for i, example in enumerate(dataset):
    

            inputs = process_image(example["img"], image_processor)
            inputs = {k: v.to(device) for k, v in inputs.items()}
            
            predicted_class_idx = classify_image(model, inputs)
            predicted_class = model.config.id2label[predicted_class_idx]
            
            print(f"Image {i}, Predicted class: {predicted_class}")
            
    
            if i >=1000:
                break

if __name__ == "__main__":
    main()

# Print PyTorch and Transformers versions for debugging
