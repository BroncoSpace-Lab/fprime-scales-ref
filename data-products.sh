#!/usr/bin/env bash

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # Get current project root
DICTIONARY="${PROJECT_DIR}/GDS-Dictionary/GDSDictionary.json" # Path to Gds dictionary

# Directory containing the .fdp files
DATA_DIR="${PROJECT_DIR}/DataProducts"

# Output directory
OUTPUT_DIR="${DATA_DIR}/decoded"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through every .fdp file
for file in "$DATA_DIR"/*.fdp; do
    # Skip if no .fdp files exist
    [ -e "$file" ] || continue

    # Get filename without extension
    base=$(basename "$file" .fdp)

    echo "Decoding $base.fdp..."

    fprime-dp decode \
        --bin-file "$file" \
        --dictionary "$DICTIONARY" \
        --output "$OUTPUT_DIR/$base.json"
done

echo "Finised Decoding!"