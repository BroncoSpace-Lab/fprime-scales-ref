from transformers import pipeline
import torch
from PIL import Image
from datasets import load_dataset
from tqdm import tqdm
import time
import numpy as np

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
        if self.start_time is None or self.frame_count == 0:
            return 0.0
        elapsed_time = time.time() - self.start_time
        if elapsed_time == 0:
            return 0.0
        return self.frame_count / elapsed_time

def process_image(pipe, image):
    """Process a single image and return the depth prediction"""
    # Convert numpy array to PIL Image
    if isinstance(image, np.ndarray):
        image = Image.fromarray(image)
    
    # Get the prediction
    predictions = pipe(image, return_tensors=True)
    
    # Extract the depth tensor
    depth_tensor = predictions["predicted_depth"]
    
    return depth_tensor

def main():
    # Set up device and model
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Using device: {device}")

    total_frames = 1000
    
    checkpoint = "depth-anything/Depth-Anything-V2-base-hf"
    pipe = pipeline("depth-estimation", model=checkpoint, device=device)

    # Load CIFAR-100 dataset
    dataset = load_dataset("cifar100", split="test")
    print(f"Loaded CIFAR-100 test set with {len(dataset)} images")

    # Initialize FPS meter
    fps_meter = FPSMeter()
    print(f"\nStarting inference on {device}...")
    fps_meter.start()

    successful_predictions = 0
    failed_predictions = 0

    total_frames = 1000
    
    # Process each image
    for idx in tqdm(range(total_frames)):
        example = dataset[idx]
        image = example['img']  # This is a numpy array
        
        try:
            # Process image and get depth tensor
            depth_tensor = process_image(pipe, image)
            
            # Update metrics
            fps_meter.update()
            successful_predictions += 1
            
            if idx % 1000 == 0 and idx > 0:  # Print FPS every 100 images
                current_fps = fps_meter.get_fps()
                print(f"\nCurrent FPS: {current_fps:.2f}")
                print(f"Successful/Failed: {successful_predictions}/{failed_predictions}")
            
        except Exception as e:
            failed_predictions += 1
            if failed_predictions < 10:  # Only print first 10 errors to avoid spam
                print(f"Error processing image {idx}: {str(e)}")
            continue

    # Final statistics
    total_time = time.time() - fps_meter.start_time
    total_processed = successful_predictions

    print(f"\nProcessing complete!")
    print(f"Successfully processed: {successful_predictions} images")
    print(f"Failed to process: {failed_predictions} images")
    
    if total_processed > 0:
        print(f"Total time: {total_time:.2f} seconds")
        print(f"Average FPS: {fps_meter.get_fps():.2f}")
        print(f"Average time per image: {(total_time/total_processed)*1000:.2f} ms")
    else:
        print("No images were successfully processed.")

if __name__ == "__main__":
    main()