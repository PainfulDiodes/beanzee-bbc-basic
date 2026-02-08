#!/usr/bin/env bash

# Remove build artifacts (object files, binaries, listings, maps)
# Preserves converted .asm source files
# Usage: build/clean.sh

set -e

BUILD_DIR="build"

count=0
for pattern in "$BUILD_DIR"/*.o "$BUILD_DIR"/*.bin "$BUILD_DIR"/*.map "$BUILD_DIR"/*.lis; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            rm -f "$file"
            count=$((count + 1))
        fi
    done
done

if [ "$count" -gt 0 ]; then
    echo "Removed $count build artifact(s) from $BUILD_DIR/"
else
    echo "Nothing to clean"
fi
