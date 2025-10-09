import onnx
import onnxruntime as ort
import torch
import torchvision.transforms as transforms
from torch.utils.data import DataLoader
from torchvision.datasets import MNIST
import numpy as np


def main():
    model_path = 'mnist.onnx'
    onnx_model = onnx.load(model_path)
    onnx.checker.check_model(onnx_model)

    session = ort.InferenceSession(model_path)

    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.5, ), (0.5, ))
    ])

    test_dataset = MNIST(root='./data', train=False, download=True, transform=transform)
    test_loader = DataLoader(dataset=test_dataset, batch_size=32, shuffle=False)

if __name__ == '__main__':
    main()
