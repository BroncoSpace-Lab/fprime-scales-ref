import torch
from transformers import AutoImageProcessor, ResNetForImageClassification
from datasets import load_dataset
from PIL import Image
import os
import numpy as np
import time
import pandas as pd
from collections import deque
from datetime import datetime, timedelta
import pickle


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
    probabilities = torch.nn.functional.softmax(logits,dim=-1)
    predicted_class_idx = torch.argmax(logits,dim=-1).item()
    return predicted_class_idx, probabilities[0]

def create_reference_df(predictions_df, min_samples_per_class = 10):
     
    reference_df = []
    for class_label in predictions_df['y_true'].unique():
          class_data = predictions_df[predictions_df['y_true']== class_label].copy()
          
          if len(class_data) < min_samples_per_class * 2:
            print(f"Warning: Class {class_label} has fewer than {min_samples_per_class * 2} samples")
            continue
          reference_df.append(class_data)
          
    reference_df = pd.concat(reference_df, ignore_index=True)

    return reference_df
    
def main(model_name="microsoft/resnet-152"):
    dataset = load_dataset("uoft-cs/cifar100",split="train")
    model, image_processor = load_model_and_processor(model_name)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = model.to(device)
    class_counts = {}
    predictions = []
    start_time = datetime.now()

    for i, example in enumerate(dataset):
    
            true_label = example["fine_label"]

            inputs = process_image(example["img"], image_processor)
            inputs = {k: v.to(device) for k, v in inputs.items()}
            
            predicted_class_idx, probabilities = classify_image(model, inputs)
            predicted_class = model.config.id2label[predicted_class_idx]
            
            #print(f"Image {i}, Predicted class: {predicted_class}")

            time = start_time + timedelta(seconds=i)
            time = time.replace(microsecond=0)

            
            pred_data = {
                'y_true': true_label,
                'y_pred': predicted_class_idx,
                'timestamp': i,
                'time': time
            }

            for class_idx, prob in enumerate(probabilities.cpu().numpy()):
                pred_data[f'pred_proba_{class_idx}'] = prob

            predictions.append(pred_data)
            class_counts[true_label] = class_counts.get(true_label, 0) + 1

            if (i + 1) % 100 == 0:
                print(f"Processed {i + 1} images from training set")

            if i >=500:
                break
            reference_df = pd.DataFrame(predictions)
            reference_df.to_pickle('/home/scalesagx/Scales-ML/nannyml/ref_df')

    return reference_df

if __name__ == "__main__":
    main()

    

# Print PyTorch and Transformers versions for debugging
