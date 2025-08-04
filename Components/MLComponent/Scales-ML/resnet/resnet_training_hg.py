import torch
import torch.nn as nn
import torch.optim as optim
import torchvision
import torchvision.transforms as transforms
from torch.utils.data import DataLoader, Dataset
from torchvision.models import resnet50
import time
from tqdm import tqdm
from datasets import load_dataset
import numpy as np
from datetime import datetime, timedelta
from huggingface_hub import PyTorchModelHubMixin
from safetensors.torch import save_model
from transformers import AutoTokenizer


# Set random seed for reproducibility
torch.manual_seed(42)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Hyperparameters
BATCH_SIZE = 128
NUM_EPOCHS = 1
LEARNING_RATE = 0.1
MOMENTUM = 0.9
WEIGHT_DECAY = 5e-4
repo_url = "https://huggingface.co/zegaines/scales-resnet"

class CIFAR100Dataset(Dataset):
    def __init__(self, dataset, transform=None):
        self.dataset = dataset
        self.transform = transform

    def __len__(self):
        return len(self.dataset)

    def __getitem__(self, idx):
        image = self.dataset[idx]['img']
        label = self.dataset[idx]['fine_label']
        
        if self.transform:
            image = self.transform(image)
        else:
            image = transforms.ToTensor()(image)
            
        return image, label

class CustomResNet(nn.Module, PyTorchModelHubMixin):
    """
    Custom ResNet model for CIFAR100 with Hugging Face Hub integration
    """
    # Metadata for the model card
    repo_url = "https://huggingface.co/zegaines/scales-resnet"
    pipeline_tag = "image-classification"
    license = "mit"
    
    def __init__(self, num_classes=100):
        super().__init__()
        # Initialize ResNet model
        self.model = resnet50(num_classes=num_classes)
        # Modify first conv layer and remove maxpool for CIFAR100
        self.model.conv1 = nn.Conv2d(3, 64, kernel_size=3, stride=1, padding=1, bias=False)
        self.model.maxpool = nn.Identity()
        
    def forward(self, x):
        return self.model(x)
    


def format_time(seconds):
    return str(timedelta(seconds=int(seconds)))

def format_timespan(start_time, end_time):
    elapsed_time = end_time - start_time
    hours = int(elapsed_time // 3600)
    minutes = int((elapsed_time % 3600) // 60)
    seconds = int(elapsed_time % 60)
    return f"{hours:02d}:{minutes:02d}:{seconds:02d}"

# Data augmentation and normalization for training
transform_train = transforms.Compose([
    transforms.RandomCrop(32, padding=4),
    transforms.RandomHorizontalFlip(),
    transforms.ToTensor(),
    transforms.Normalize((0.5071, 0.4867, 0.4408), (0.2675, 0.2565, 0.2761))
])

transform_test = transforms.Compose([
    transforms.ToTensor(),
    transforms.Normalize((0.5071, 0.4867, 0.4408), (0.2675, 0.2565, 0.2761))
])

# Load CIFAR100 dataset using Hugging Face datasets
print("Loading dataset...")
dataset = load_dataset("cifar100")

# Create custom datasets
trainset = CIFAR100Dataset(dataset['train'], transform=transform_train)
testset = CIFAR100Dataset(dataset['test'], transform=transform_test)

# Create data loaders
trainloader = DataLoader(trainset, batch_size=BATCH_SIZE,
                        shuffle=True, num_workers=2)
testloader = DataLoader(testset, batch_size=BATCH_SIZE,
                       shuffle=False, num_workers=2)

print(f"Training on {device}")
print(f"Total training batches: {len(trainloader)}")
print(f"Total test batches: {len(testloader)}")

# Create ResNet model
model = CustomResNet(num_classes=100)
model = model.to(device)

# Loss function and optimizer
criterion = nn.CrossEntropyLoss()
optimizer = optim.SGD(model.parameters(), lr=LEARNING_RATE,
                     momentum=MOMENTUM, weight_decay=WEIGHT_DECAY)

# Learning rate scheduler
scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=NUM_EPOCHS)

def train_epoch(model, trainloader, criterion, optimizer):
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0
    
    pbar = tqdm(trainloader, desc='Training')
    for inputs, targets in pbar:
        inputs, targets = inputs.to(device), targets.to(device)
        
        optimizer.zero_grad()
        outputs = model(inputs)
        loss = criterion(outputs, targets)
        loss.backward()
        optimizer.step()
        
        running_loss += loss.item()
        _, predicted = outputs.max(1)
        total += targets.size(0)
        correct += predicted.eq(targets).sum().item()
        
        pbar.set_postfix({'loss': running_loss/len(trainloader),
                         'acc': 100.*correct/total})
    
    return running_loss/len(trainloader), 100.*correct/total

def evaluate(model, testloader, criterion):
    model.eval()
    test_loss = 0
    correct = 0
    total = 0
    
    with torch.no_grad():
        for inputs, targets in tqdm(testloader, desc='Testing'):
            inputs, targets = inputs.to(device), targets.to(device)
            outputs = model(inputs)
            loss = criterion(outputs, targets)
            
            test_loss += loss.item()
            _, predicted = outputs.max(1)
            total += targets.size(0)
            correct += predicted.eq(targets).sum().item()
    
    return test_loss/len(testloader), 100.*correct/total

def push_model_to_hub(model, metrics, repo_name):
    """
    Push the trained model and its metrics to Hugging Face Hub
    """
    try:
        # Push to hub
        model.push_to_hub(repo_name)
        model.save_pretrained(repo_name, push_to_hub = True)
        tokenizer.push_to_hub(repo_name)
        print(f"Model successfully pushed to https://huggingface.co/{repo_name}")
    except Exception as e:
        print(f"Error pushing to hub: {str(e)}")

# Initialize timing metrics
total_start_time = time.time()
epoch_times = []
best_acc = 0

print("\nStarting training...")
print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

# Training loop
for epoch in range(NUM_EPOCHS):
    epoch_start_time = time.time()
    
    print(f'\nEpoch: {epoch+1}/{NUM_EPOCHS}')
    
    train_loss, train_acc = train_epoch(model, trainloader, criterion, optimizer)
    test_loss, test_acc = evaluate(model, testloader, criterion)
    
    scheduler.step()
    
    epoch_end_time = time.time()
    epoch_duration = epoch_end_time - epoch_start_time
    epoch_times.append(epoch_duration)
    
    # Calculate estimated time remaining
    avg_epoch_time = sum(epoch_times) / len(epoch_times)
    epochs_remaining = NUM_EPOCHS - (epoch + 1)
    estimated_time_remaining = avg_epoch_time * epochs_remaining
    
    print(f'Train Loss: {train_loss:.3f} | Train Acc: {train_acc:.2f}%')
    print(f'Test Loss: {test_loss:.3f} | Test Acc: {test_acc:.2f}%')
    print(f'Epoch time: {format_time(epoch_duration)}')
    print(f'Average epoch time: {format_time(avg_epoch_time)}')
    print(f'Estimated time remaining: {format_time(estimated_time_remaining)}')
    
    # Save checkpoint
    if test_acc > best_acc:
        print('Saving checkpoint...')
        state = {
            'model': model.state_dict(),
            'acc': test_acc,
            'epoch': epoch,
        }
        torch.save(state, '/home/broncospace/Scales-ML/resnet/resnet_cifar100.pth')
        best_acc = test_acc

total_end_time = time.time()
total_training_time = total_end_time - total_start_time

print("\nTraining completed!")
print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"Total training time: {format_timespan(total_start_time, total_end_time)}")
print(f"Average epoch time: {format_time(sum(epoch_times) / len(epoch_times))}")
print(f"Fastest epoch: {format_time(min(epoch_times))}")
print(f"Slowest epoch: {format_time(max(epoch_times))}")
print(f"Best test accuracy: {best_acc:.2f}%")

# Save training metrics
metrics = {
    'total_training_time': total_training_time,
    'epoch_times': epoch_times,
    'average_epoch_time': sum(epoch_times) / len(epoch_times),
    'fastest_epoch': min(epoch_times),
    'slowest_epoch': max(epoch_times),
    'best_accuracy': best_acc
}

push_model_to_hub(model,"zegaines/scales-resnet",repo_name = "zegaines/scales-resnet")
print("model saved")


