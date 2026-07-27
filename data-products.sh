#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DICTIONARY="${PROJECT_DIR}/GDS-Dictionary/GDSDictionary.json"
DATA_DIR="${PROJECT_DIR}/DataProducts"
OUTPUT_DIR="${DATA_DIR}/decoded"

mkdir -p "$OUTPUT_DIR"

found_files=false

for file in "$DATA_DIR"/*.fdp; do
    [ -e "$file" ] || continue
    found_files=true

    filename="$(basename "$file")"
    base="${filename%.fdp}"

    # Decode into a temporary file first because the container ID is
    # determined from the decoded JSON, not from the filename.
    temp_output="$(mktemp "${OUTPUT_DIR}/.decode.XXXXXX")"

    echo "Decoding $filename..."

    if ! fprime-dp decode \
        --bin-file "$file" \
        --dictionary "$DICTIONARY" \
        --output "$temp_output"; then

        echo "ERROR: Failed to decode $filename"
        rm -f "$temp_output"
        continue
    fi

    # Dynamically read Header.Id.value from the decoded JSON.
    container_id="$(
        python3 - "$temp_output" <<'PY'
import json
import sys

json_path = sys.argv[1]

with open(json_path, "r", encoding="utf-8") as file:
    data = json.load(file)

print(data["Header"]["Id"]["value"])
PY
    )"

    # Make sure the extracted ID is valid.
    if [[ ! "$container_id" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Invalid container ID '$container_id' in $filename"
        rm -f "$temp_output"
        continue
    fi

    container_output_dir="${OUTPUT_DIR}/${container_id}"
    output_file="${container_output_dir}/${base}.json"

    mkdir -p "$container_output_dir"
    mv "$temp_output" "$output_file"

    echo "  Container ID: $container_id"
    echo "  Output: $output_file"
done

if [ "$found_files" = false ]; then
    echo "No .fdp files found in $DATA_DIR"
    exit 0
fi

echo "Finished decoding data products."