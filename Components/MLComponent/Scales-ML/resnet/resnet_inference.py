import torch
from transformers import AutoImageProcessor, ResNetForImageClassification
from PIL import Image
import os


def load_model_and_processor(model_name="microsoft/resnet-18"):
    image_processor = AutoImageProcessor.from_pretrained(model_name)
    model = ResNetForImageClassification.from_pretrained(model_name)
    return model, image_processor

def process_image(image_path, image_processor):
    image = Image.open(image_path).convert("RGB")
    inputs = image_processor(images=image, return_tensors="pt")
    return inputs

def classify_image(model, inputs):
    with torch.no_grad():
        outputs = model(**inputs)
    logits = outputs.logits
    predicted_class_idx = torch.argmax(logits, dim=-1).item()
    return predicted_class_idx

def main(folder_path, model_name="microsoft/resnet-18"):
    model, image_processor = load_model_and_processor(model_name)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = model.to(device)
    
    output = []

    for filename in os.listdir(folder_path):
        if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
            image_path = os.path.join(folder_path, filename)
            inputs = process_image(image_path, image_processor)
            inputs = {k: v.to(device) for k, v in inputs.items()}
            
            predicted_class_idx = classify_image(model, inputs)
            predicted_class = model.config.id2label[predicted_class_idx]
            
            output.append((filename, predicted_class))
            
            # print(f"Image: {filename}, Predicted class: {predicted_class}")
    
    return output

if __name__ == "__main__":
    folder_path = "/home/scalesagx/scales_ws/Depth-Anything-V2/assets/examples"
    main(folder_path)

# Print PyTorch and Transformers versions for debugging
