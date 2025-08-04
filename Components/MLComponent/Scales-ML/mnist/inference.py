from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Dense, Flatten
from tensorflow.keras.datasets import mnist
import cv2
from tensorflow import convert_to_tensor
from matplotlib.image import imread
import numpy as np


def main():
    (train_images, train_labels), (test_images, test_labels) = mnist.load_data()

    train_images = (train_images / 255) - 0.5
    test_images = (test_images / 255) - 0.5

    train_images = np.expand_dims(train_images, axis=3)
    test_images = np.expand_dims(test_images, axis=3)

    num_filters = 8
    filter_size = 3
    pool_size = 2

    model = Sequential([
        Conv2D(num_filters, filter_size, input_shape=(28, 28, 1)),
        MaxPooling2D(pool_size=pool_size),
        Flatten(),
        Dense(10, activation='softmax'),
    ])

    model.load_weights('cnn.weights.h5')

    predictions = model.predict(test_images)

    predicted_labels = np.argmax(predictions, axis=1)

    correct_predictions = np.sum(predicted_labels == test_labels)
    total_examples = test_images.shape[0]
    accuracy = correct_predictions / total_examples
    print(f'Accuracy: {accuracy}')
    

def preparse(img):
    
    img = img * 255
    img = img.astype(np.uint8)
    
        
    # Convert to grayscale if it's not already
    if len(img.shape) == 3:
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
  

    # Normalize pixel values to [-0.5, 0.5] range (same as training data)
    img = (img / 255) - 0.5
    test_img = (test_img / 255) - 0.5    


    img = np.expand_dims(img, axis=0)  # Add batch dimension
    img = np.expand_dims(img, axis=-1)  # Add channel dimension
    
    return img
    
def infer(img_tensor):
    
    num_filters = 8
    filter_size = 3
    pool_size = 2

    model = Sequential([
        Conv2D(num_filters, filter_size, input_shape=(28, 28, 1)),
        MaxPooling2D(pool_size=pool_size),
        Flatten(),
        Dense(10, activation='softmax'),
    ])
    
    model.load_weights('cnn.weights.h5')
    
    prediction = model.predict(img_tensor, batch_size=0)
    return np.argmax(prediction)


if __name__ == '__main__':
    image = imread('test/8_index17.png')
    img_tensor = preparse(image)
    prediction = infer(img_tensor)
    print(prediction)
    
    pass
    # main()