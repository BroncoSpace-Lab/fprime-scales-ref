from datasets import load_dataset, Audio
from transformers import AutoModelForAudioClassification, AutoFeatureExtractor
from torch.utils.data import DataLoader

def preprocess_function(examples):
    audio_arrays = [x["array"] for x in examples["audio"]]
    inputs = feature_extractor(
        audio_arrays,
        sampling_rate=16000,
        padding=True,
        max_length=100000,
        truncation=True
    )
    return inputs

dataset = load_dataset("PolyAI/minds14", "en-US", split="train")
model = AutoModelForAudioClassification.from_pretrained("facebook/wav2vec2-base")
feature_extractor = AutoFeatureExtractor.from_pretrained("facebook/wav2vec2-base")

dataset = dataset.cast_column("audio", Audio(sampling_rate=16000))
dataset = dataset.map(preprocess_function, batched=True)
dataset = dataset.rename_column("intent_class", "labels")

dataset.set_format(type="torch", columns=["input_values", "labels"])
dataloader = DataLoader(dataset, batch_size=4)


