#!/usr/bin/env bash

# Remove converted source files
# Usage: ./clean-converted.sh

set -e

ASM_DIR="asm"

if [ -d "$ASM_DIR" ]; then
    rm -rf "$ASM_DIR"
    echo "Removed $ASM_DIR/"
else
    echo "Nothing to clean - $ASM_DIR/ does not exist"
fi
