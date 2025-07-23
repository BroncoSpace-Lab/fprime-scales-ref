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


def infer(model, test_loader, device):
    model.to(device)
    model.eval()
    all_predictions = []
    all_labels = []
    with torch.no_grad():
        for inputs, labels in test_loader:
            inputs, labels = inputs.to(device), labels.to(device)
            outputs = model(inputs)
            _, predicted = torch.max(outputs, 1)
            all_predictions.extend(predicted.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())

    return all_predictions, all_labels


def calculate_accuracy(predictions, labels):
    correct = sum(p == l for p, l in zip(predictions, labels))
    total = len(labels)
    accuracy = correct / total
    return accuracy


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

    predictions, labels = infer(model, test_loader, device)

    accuracy = calculate_accuracy(predictions, labels)

    print(f'Accuracy: {accuracy:.4f}')


if __name__ == '__main__':
    main()