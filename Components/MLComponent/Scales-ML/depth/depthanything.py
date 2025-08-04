from transformers import pipeline
import torch
import PIL
from PIL import Image
import os
from datasets import Dataset
from tqdm import tqdm  # for progress bar


def load_data(folder_path):
    """Load image paths from folder into a dataset"""
    image_files = [f for f in os.listdir(folder_path) 
                  if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
    
    data_dict = {
        "image_path": [os.path.join(folder_path, img) for img in image_files],
        "file_name": image_files
    }

    dataset = Dataset.from_dict(data_dict)
    return dataset

def main(folder_path):
    # Set up device and model
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Using device: {device}")
    
    checkpoint = "depth-anything/Depth-Anything-V2-base-hf"
    pipe = pipeline("depth-estimation", model=checkpoint, device=device)

    # Load dataset
    dataset = load_data(folder_path)
    print(f"Found {len(dataset)} images")

    # Process each image
    for i, idx in tqdm(range(len(dataset))):
        
        example = dataset[idx]
        image_path = example['image_path']
        filename = example['file_name']
        
        try:
            # Load and process image
            image = Image.open(image_path)
            predictions = pipe(image)
            depth = predictions["predicted_depth"]
            depth_image = predictions["depth"]
            
            # Save depth map
            output_filename = f"depth_{filename}"
            depth_image.save(os.path.join(output_path, output_filename))
            #print(depth)
            
            print(f"Processed {filename} - Depth map saved as {output_filename}")
            
        except Exception as e:
            print(f"Error processing {filename}: {str(e)}")

if __name__ == "__main__":
    folder_path = "/home/scalesagx/scales_ws/Depth-Anything-V2/assets/examples"
    output_path = "/home/scalesagx/Scales-ML/depth/output"
    main(folder_path)