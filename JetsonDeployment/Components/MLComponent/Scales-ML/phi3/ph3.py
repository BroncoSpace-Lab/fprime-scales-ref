import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
import time
from datetime import datetime

torch.random.manual_seed(0)

# Start total runtime timer
start_time = time.time()

model = AutoModelForCausalLM.from_pretrained(
    "microsoft/Phi-3.5-mini-instruct", 
    device_map="cuda", 
    torch_dtype="auto", 
    trust_remote_code=True,
)
tokenizer = AutoTokenizer.from_pretrained("microsoft/Phi-3.5-mini-instruct")

messages = [
    {"role": "system", "content": "You are a helpful AI assistant."},
    {"role": "user", "content": "Can you write an essay about trees"},
]

# Convert messages to a single string
formatted_prompt = " ".join([f"{msg['role']}: {msg['content']}" for msg in messages])

# Create the pipeline
pipe = pipeline(
    "text-generation",
    model=model,
    tokenizer=tokenizer,
)

generation_args = {
    "max_new_tokens": 500,
    "return_full_text": False,
    "temperature": 0.0,
    "do_sample": False,
}

# Get initial token count
input_ids = tokenizer(formatted_prompt, return_tensors="pt")["input_ids"]
initial_tokens = input_ids.shape[1]

# Start generation timer
gen_start = time.time()

# Run generation
output = pipe(formatted_prompt, **generation_args)

# Calculate metrics
gen_end = time.time()
gen_time = gen_end - gen_start

# Count generated tokens
output_text = output[0]['generated_text']
total_tokens = len(tokenizer.encode(output_text))
new_tokens = total_tokens - initial_tokens

# Calculate tokens per second
tokens_per_second = new_tokens / gen_time

print(f"\nGeneration Statistics:")
print(f"New tokens generated: {new_tokens}")
print(f"Generation time: {gen_time:.2f} seconds")
print(f"Tokens per second: {tokens_per_second:.2f}")

print("\nGenerated Text:")
print(output_text)

# Calculate and print total runtime
total_time = time.time() - start_time
print(f"\nTotal Runtime: {total_time:.2f} seconds")
