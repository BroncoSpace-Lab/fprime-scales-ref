# Jetson ML Dependencies Documentation

## Overview
This document lists all ML dependencies required to run the F-Prime flight software with ML components on NVIDIA Jetson (JetPack R36.5, aarch64, Python 3.11.0rc1).

## Dependency Versions

### Core ML Framework
| Package | Version | Purpose |
|---------|---------|---------|
| `torch` | 2.4.0 | Deep learning framework (CPU version via PyTorch wheels) |
| `transformers` | 4.33.0 | HuggingFace transformers library for ResNet and image classification |
| `datasets` | 2.13.0 | Dataset handling utilities |

### Image Processing
| Package | Version | Purpose |
|---------|---------|---------|
| `pillow` | ≥10.0.0 | Python Imaging Library for image processing |
| `numpy` | <2.0 | Numerical computing (must stay <2.0 for torch 2.4.0 compatibility) |

### Support Libraries
| Package | Version | Purpose |
|---------|---------|---------|
| `huggingface-hub` | ≥0.16.0 | Model downloading and caching |
| `tokenizers` | ≥0.13.0 | Fast tokenizers for NLP |
| `safetensors` | ≥0.3.1 | Safe model serialization |
| `tqdm` | ≥4.62.0 | Progress bars |

## Installation

### Option 1: Automatic (Recommended)
```bash
make ml-deps-jetson
```

This installs all dependencies from `requirements-jetson-ml.txt` with the correct PyTorch CPU wheel index.

### Option 2: Manual
```bash
fprime-venv/bin/pip install -r requirements-jetson-ml.txt --index-url https://download.pytorch.org/whl/cpu
```

### Option 3: One-liner during setup
The `make build-jetson` target now automatically installs these dependencies before building.

## Compatibility Notes

### Why These Specific Versions?

1. **torch 2.4.0**: 
   - Last version that works with Python 3.11.0rc1 without `sys.get_int_max_str_digits` errors
   - Newer torch versions expect Python 3.11.10+ or 3.12+
   - CPU wheel available on PyPI for aarch64

2. **transformers 4.33.0**: 
   - Compatible with torch 2.4.0
   - Supports `ResNetForImageClassification` (required for resnet_cifar100.py)
   - Newer versions (5.x) require torch ≥2.4.4 and break on this setup

3. **numpy <2.0**: 
   - torch 2.4.0 was compiled against numpy 1.x
   - numpy 2.x causes runtime errors due to ABI incompatibility
   - Use `numpy>=1.20,<2.0` to stay safe

## Common Issues & Solutions

### Issue: `AttributeError: module 'sys' has no attribute 'get_int_max_str_digits'`
**Cause**: torch version too new for Python 3.11.0rc1  
**Solution**: Ensure `torch==2.4.0` is installed (not latest)

### Issue: `ModuleNotFoundError: No module named 'torch.distributed.tensor.device_mesh'`
**Cause**: transformers version too new for torch 2.4.0  
**Solution**: Use `transformers==4.33.0` (not latest)

### Issue: NumPy ABI mismatch error
**Cause**: numpy 2.x installed with torch compiled for numpy 1.x  
**Solution**: Run `pip install 'numpy<2.0'`

### Issue: `ModuleNotFoundError: No module named 'torch'` when running `./jetson-startup.sh`
**Cause**: ML dependencies not installed  
**Solution**: Run `make ml-deps-jetson` or `make build-jetson`

## Environment Variables (jetson-startup.sh)

The startup script automatically sets `LD_LIBRARY_PATH` to include Arena SDK libraries:
```bash
export LD_LIBRARY_PATH="/home/scales/fprime-scales-ref/lib/ArenaSDK/lib:..."
```

This allows the native `python_extension.so` to resolve its dependencies at runtime.

## Testing

To verify all dependencies are working:
```bash
fprime-venv/bin/python -c "import torch; from transformers import AutoImageProcessor, ResNetForImageClassification; print('✓ All dependencies OK')"
```

## References

- PyTorch CPU wheels: https://download.pytorch.org/whl/cpu
- JetPack R36.5 info: https://developer.nvidia.com/embedded/jetpack
- HuggingFace Transformers: https://github.com/huggingface/transformers
