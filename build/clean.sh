#!/usr/bin/env bash

# Remove build artifacts (object files, binaries, listings, maps)
# Preserves converted .asm source files
# Usage: cd build && ./clean.sh

set -e

# Run from the script's directory
cd "$(dirname "$0")"

count=0
for pattern in *.o *.lis; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            rm -f "$file"
            count=$((count + 1))
        fi
    done
done

for target_dir in cpm acorn; do
    for pattern in "$target_dir"/*.bin "$target_dir"/*.hex "$target_dir"/*.map; do
        for file in $pattern; do
            if [ -f "$file" ]; then
                rm -f "$file"
                count=$((count + 1))
            fi
        done
    done
done

if [ "$count" -gt 0 ]; then
    echo "Removed $count build artifact(s)"
else
    echo "Nothing to clean"
fi
