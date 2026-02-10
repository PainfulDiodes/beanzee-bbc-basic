#!/usr/bin/env bash

# Remove all generated files from build/ (converted source and build artifacts)
# Preserves tracked scripts (build.sh, clean.sh)
# Usage: ./clean.sh

set -e

BUILD_DIR="build"

count=0
for pattern in "$BUILD_DIR"/*.asm "$BUILD_DIR"/*.inc "$BUILD_DIR"/*.o "$BUILD_DIR"/*.bin "$BUILD_DIR"/*.map "$BUILD_DIR"/*.lis; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            rm -f "$file"
            count=$((count + 1))
        fi
    done
done

if [ "$count" -gt 0 ]; then
    echo "Removed $count generated file(s) from $BUILD_DIR/"
else
    echo "Nothing to clean - no generated files in $BUILD_DIR/"
fi
