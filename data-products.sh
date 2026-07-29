#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DICTIONARY="${PROJECT_DIR}/GDS-Dictionary/GDSDictionary.json"
DATA_DIR="${PROJECT_DIR}/DataProducts"
OUTPUT_DIR="${DATA_DIR}/decoded"

# Script that creates one CSV per container ID.
MERGE_SCRIPT="${PROJECT_DIR}/DataProducts/merge_data_products_by_container.py"
CSV_OUTPUT_DIR="${OUTPUT_DIR}/csv"

mkdir -p "$OUTPUT_DIR"

# Check required files before starting.
if [[ ! -f "$DICTIONARY" ]]; then
    echo "ERROR: Dictionary not found:"
    echo "       $DICTIONARY"
    exit 1
fi

if [[ ! -f "$MERGE_SCRIPT" ]]; then
    echo "ERROR: CSV conversion script not found:"
    echo "       $MERGE_SCRIPT"
    exit 1
fi

found_files=false

for file in "$DATA_DIR"/*.fdp; do
    # Handles the case where the glob matches no files.
    [[ -e "$file" ]] || continue

    found_files=true

    filename="$(basename "$file")"
    base="${filename%.fdp}"

    # Decode to a temporary file because the folder name depends on
    # the container ID stored inside the decoded JSON.
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

    # Read Header.Id.value dynamically from the decoded JSON.
    if ! container_id="$(
        python3 - "$temp_output" <<'PY'
import json
import sys

json_path = sys.argv[1]

with open(json_path, "r", encoding="utf-8") as json_file:
    data = json.load(json_file)

container_id = data["Header"]["Id"]["value"]
print(container_id)
PY
    )"; then
        echo "ERROR: Failed to read the container ID from $filename"
        rm -f "$temp_output"
        continue
    fi

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
    echo "  Output:       $output_file"
done

if [[ "$found_files" == false ]]; then
    echo "No new .fdp files found in $DATA_DIR"
    echo "Rebuilding CSV files from existing decoded JSON files."
fi

# Make sure there is at least one decoded JSON file before creating CSVs.
first_json="$(find "$OUTPUT_DIR" -type f -name '*.json' -print -quit)"

if [[ -z "$first_json" ]]; then
    echo "No decoded JSON files found under $OUTPUT_DIR"
    exit 0
fi

# Remove the old combined CSV, if it exists.
rm -f "${OUTPUT_DIR}/merged_records.csv"

echo
echo "Creating one CSV per data-product container..."

python3 "$MERGE_SCRIPT" \
    "$OUTPUT_DIR" \
    --output-dir "$CSV_OUTPUT_DIR" \
    --layout wide \
    --round-digits 4

echo
echo "Finished decoding and converting data products."
echo "CSV output directory: $CSV_OUTPUT_DIR"