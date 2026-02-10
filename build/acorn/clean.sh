#!/usr/bin/env bash

# Clean build artifacts for Acorn tube target
# Preserves converted .asm source files
# Usage: cd build/acorn && ./clean.sh

set -e
cd "$(dirname "$0")"

count=0
for pattern in *.o *.bin *.map *.lis *.hex; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            rm -f "$file"
            count=$((count + 1))
        fi
    done
done

if [ "$count" -gt 0 ]; then
    echo "Removed $count build artifact(s)"
else
    echo "Nothing to clean"
fi
