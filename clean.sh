#!/usr/bin/env bash

# Remove build output files
# Usage: ./clean.sh

set -e

OUTPUT_DIR="output"

if [ -d "$OUTPUT_DIR" ]; then
    rm -rf "$OUTPUT_DIR"
    echo "Removed $OUTPUT_DIR/"
else
    echo "Nothing to clean - $OUTPUT_DIR/ does not exist"
fi
