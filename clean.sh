#!/usr/bin/env bash

# Clean build artifacts for all targets
# Usage: ./clean.sh

set -e
cd "$(dirname "$0")"

TARGETS="acorn beanzee cpm"

for target in $TARGETS; do
    echo "Cleaning $target..."
    ./targets/$target/clean.sh
done
