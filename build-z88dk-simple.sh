#!/usr/bin/env bash

# Simplified z88dk build script for BBC BASIC Z80
# Uses include-based approach (like Marvin)
#
# Usage:
#   ./build-z88dk-simple.sh             # Build CP/M version
#   ./build-z88dk-simple.sh cpm         # Build CP/M version
#   ./build-z88dk-simple.sh acorn       # Build Acorn tube version
#
# This approach uses wrapper files (cpm.asm, acorn.asm) that include
# all modules in the correct order. Simpler but requires removing
# GLOBAL/EXTRN directives from source files.

set -e

OUTPUT_DIR="output"
TARGET="${1:-cpm}"

mkdir -p "$OUTPUT_DIR"

case "$TARGET" in
    cpm)
        ENTRY="cpm.asm"
        OUTPUT_NAME="bbcbasic"
        ORG="0x0100"
        ;;
    acorn)
        ENTRY="acorn.asm"
        OUTPUT_NAME="bbctube"
        ORG="0x0100"
        ;;
    *)
        echo "Unknown target: $TARGET"
        exit 1
        ;;
esac

echo "Building BBC BASIC Z80 ($TARGET) - include method"
echo "================================================="

# Single-pass assembly with includes
z88dk-z80asm -l -b -m \
    -DBASIC_ORG=$ORG \
    "$ENTRY" \
    -O"$OUTPUT_DIR"

# Rename output
mv "$OUTPUT_DIR/${ENTRY%.*}.bin" "$OUTPUT_DIR/$OUTPUT_NAME.bin" 2>/dev/null || true

# Create hex dump
hexdump -C "$OUTPUT_DIR/$OUTPUT_NAME.bin" > "$OUTPUT_DIR/$OUTPUT_NAME.hex"

# Create Intel HEX
z88dk-appmake +hex --org $ORG \
    -b "$OUTPUT_DIR/$OUTPUT_NAME.bin" \
    -o "$OUTPUT_DIR/$OUTPUT_NAME.ihx"

echo ""
echo "Build complete: $OUTPUT_DIR/$OUTPUT_NAME.bin"
