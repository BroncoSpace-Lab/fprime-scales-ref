import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
import torchvision.transforms as transforms
from torch.utils.data import DataLoader
from torchvision.datasets import MNIST
from model import cnn_model


def calculate_accuracy(outputs, labels):
    _, predicted = torch.max(outputs, 1)
    correct = (predicted == labels).sum().item()
    accuracy = correct / labels.size(0)

    return accuracy


def train(model, train_loader, criterion, optimizer, epochs, device):
    model.to(device)
    model.train()

    for epoch in range(epochs):
        print(f'Starting epoch {epoch+1}/{epochs}')
        running_loss = 0.0
        total_correct = 0
        total_examples = 0

        for batch_idx, (inputs, labels) in enumerate(train_loader, 1):
            inputs, labels = inputs.to(device), labels.to(device)

            optimizer.zero_grad()
            outputs = model(inputs)

            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            running_loss += loss.item()

            _, predicted = torch.max(outputs, 1)
            correct = (predicted == labels).sum().item()
            total_correct += correct
            total_examples += labels.size(0)
            epoch_loss = running_loss / len(train_loader)
            epoch_accuracy = total_correct / total_examples


            # Print detailed mini-batch statistics
            if batch_idx % 100 == 0:  # Print every 100 mini-batches
                print(f'  Epoch [{epoch+1}/{epochs}], Batch [{batch_idx}/{len(train_loader)}], Accuracy: {epoch_accuracy:.4f}, Loss: {epoch_loss:.4f}')

        print(f'Epoch [{epoch+1}/{epochs}], Accuracy: {epoch_accuracy:.4f}, Loss: {epoch_loss:.4f}')
        print('')

    print('Training finished.')



def main():
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

    if torch.cuda.is_available():
        print(torch.cuda.get_device_name(0))
    print(f'Using device: {device}')

    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.5,), (0.5,))
    ])

    train_dataset = MNIST(root='./data', train=True, download=True, transform=transform)
    test_dataset = MNIST(root='./data', train=False, download=True, transform=transform)

    train_loader = DataLoader(dataset=train_dataset, batch_size=32, shuffle=True)
    test_loader = DataLoader(dataset=test_dataset, batch_size=32, shuffle=False)

    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(cnn_model.parameters(), lr=0.001)

    cnn_model.to(device)
    print('Training...')

    train(cnn_model, train_loader, criterion, optimizer, epochs=20, device=device)

    torch.save(cnn_model.state_dict(), 'pytorch_model.pth')


if __name__ == '__main__':
    main()