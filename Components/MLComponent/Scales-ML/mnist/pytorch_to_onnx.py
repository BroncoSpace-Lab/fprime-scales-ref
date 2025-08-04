import torch
import torch.nn as nn
import torchvision.transforms as transforms
from torch.utils.data import DataLoader
from torchvision.datasets import MNIST
from model import cnn_model


def load_model(model_path, device):
    cnn_model.load_state_dict(torch.load(model_path, map_location=device))
    cnn_model.to(device)
    cnn_model.eval()
    return cnn_model


def main():
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f'Using device: {device}')

    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.5, ), (0.5, ))
    ])

    test_dataset = MNIST(root='./data', train=False, download=True, transform=transform)
    test_loader = DataLoader(dataset=test_dataset, batch_size=32, shuffle=False)

    model_path = 'pytorch_model.pth'
    model = load_model(model_path, device)
    print('Model loaded. Starting inference...')

    input = next(iter(test_loader))[0]

    input = input.to(device).float()

    print(input)
    
    torch.onnx.export(model,
                      input,
                      'mnist.onnx',
                      export_params=True,
                      opset_version=10,
                      do_constant_folding=True,
                      input_names=['input'],
                      output_names=['output'],
                      dynamic_axes={
                          'input': {0 : 'batch_size'},
                          'output': {0 : 'batch_size'}
                      })


if __name__ == '__main__':
    main()