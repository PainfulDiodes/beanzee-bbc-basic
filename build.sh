#!/usr/bin/env bash

# Build all targets
# Usage: ./build.sh

set -e
cd "$(dirname "$0")"

TARGETS="acorn cpm"
failed=0

for target in $TARGETS; do
    echo ""
    ./targets/$target/build.sh
    if [ $? -ne 0 ]; then
        failed=1
    fi
done

echo ""
if [ "$failed" -eq 0 ]; then
    echo "All targets built successfully"
else
    echo "Some targets failed to build"
    exit 1
fi
