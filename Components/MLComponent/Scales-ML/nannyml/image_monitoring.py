import timm
from datasets import load_dataset
import torch
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

def get_feature_maps(num_samples=5):
    # Load CIFAR100 dataset
    dataset = load_dataset("uoft-cs/cifar100", split="test")

    # Create model
    model = timm.create_model(
        'mobilenetv3_large_100.ra_in1k',
        pretrained=True,
        features_only=True,
    )
    model = model.eval()
    
    # Get model specific transforms
    data_config = timm.data.resolve_model_data_config(model)
    transforms = timm.data.create_transform(**data_config, is_training=False)
    
    # Lists to store results
    feature_maps_list = []
    processed_features = []
    
    for i in range(num_samples):
        # Get image and label from dataset
        img = dataset['img'][i]
        label = dataset['fine_label'][i]
        
        # Apply transforms
        img_tensor = transforms(img).unsqueeze(0)
        
        # Generate feature maps
        with torch.no_grad():
            output = model(img_tensor)
            
        # Store original feature maps for visualization
        feature_maps_list.append({
            'image': img,
            'feature_maps': output
        })
        
        # Process feature maps for DataFrame
        # Flatten and concatenate all feature maps
        flat_features = []
        for layer_output in output:
            # Take mean across spatial dimensions to get one value per channel
            layer_features = layer_output.mean(dim=[2, 3]).cpu().numpy().flatten()
            flat_features.extend(layer_features)
            
        # Create a dictionary with features and label
        features_dict = {f'feature_{i}': value for i, value in enumerate(flat_features)}
        features_dict['y_true'] = label
        processed_features.append(features_dict)
        
        # Print feature map shapes for this image
        print(f"\nFeature map shapes for image {i+1}:")
        for idx, o in enumerate(output):
            print(f"Layer {idx+1}: {o.shape}")
    
    # Create DataFrame from processed features
    feature_values = pd.DataFrame(processed_features)
    
    return feature_maps_list, feature_values

def visualize_feature_maps(results, layer_index=0, feature_index=0):
    """
    Visualize specific feature maps for all processed images
    layer_index: Which layer's feature maps to visualize
    feature_index: Which feature channel to visualize
    """
    num_images = len(results)
    fig, axes = plt.subplots(2, num_images, figsize=(4*num_samples, 8))
    
    for i, result in enumerate(results):
        # Original image
        axes[0, i].imshow(result['image'])
        axes[0, i].set_title(f'Original Image {i+1}')
        axes[0, i].axis('off')
        
        # Feature map
        feature_map = result['feature_maps'][layer_index][0, feature_index].detach().cpu()
        axes[1, i].imshow(feature_map, cmap='viridis')
        axes[1, i].set_title(f'Feature Map {i+1}')
        axes[1, i].axis('off')
    
    plt.tight_layout()
    plt.show()

# Example usage
if __name__ == "__main__":
    num_samples = 5
    feature_maps_list, feature_values = get_feature_maps(num_samples=num_samples)
    
    # Print DataFrame info
    print("\nDataFrame Info:")
    print(feature_values.info())
    
    # Visualize feature maps from the first layer (layer_index=0)
    # and first feature channel (feature_index=0)
    #visualize_feature_maps(feature_maps_list, layer_index=0, feature_index=0)