#!/usr/bin/env bash

# z88dk modular build script for BBC BASIC Z80
# Usage:
#   cd build && ./build.sh             # Build CP/M version (default)
#   cd build && ./build.sh cpm         # Build CP/M version
#   cd build && ./build.sh acorn       # Build Acorn tube version
#
# Requires: z88dk with z88dk-z80asm
#
# This script builds each module separately to object files, then links them.
# This mirrors the original CP/M build process and avoids namespace collisions.
#
# Before first use, run: ./convert.sh

set -e  # Exit on error

# Run from the script's directory
cd "$(dirname "$0")"

# Target selection
TARGET="${1:-cpm}"

# Module list varies by target
case "$TARGET" in
    cpm)
        MODULES="DIST MAIN EXEC EVAL ASMB MATH HOOK CMOS DATA"
        OUTPUT_NAME="bbcbasic"
        CODE_ORG="0x0100"
        DATA_ORG="0x4B00"
        ;;
    acorn)
        MODULES="MAIN EXEC EVAL ASMB MATH ACORN AMOS DATA"
        OUTPUT_NAME="bbctube"
        CODE_ORG="0x0100"
        DATA_ORG="0x4C00"
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Usage: $0 [cpm|acorn]"
        exit 1
        ;;
esac

echo "Building BBC BASIC Z80 ($TARGET) - Modular Build"
echo "================================================="

# Check converted source files exist
if [ ! -f "MAIN.asm" ]; then
    echo "Error: Converted source files not found."
    echo "Run ./convert.sh first to convert source files."
    exit 1
fi

# Clean previous build artifacts
rm -f *.o *.bin *.map *.lis

# Assemble each module to object file
echo ""
echo "Assembling modules..."
for module in $MODULES; do
    if [ ! -f "$module.asm" ]; then
        echo "Error: $module.asm not found"
        exit 1
    fi
    echo "  $module.asm -> $module.o"
    z88dk-z80asm -l -m -o"$module.o" "$module.asm"
done

# Build object file list for linking
# All modules linked together; DATA follows code
ALL_OBJS=""
for module in $MODULES; do
    ALL_OBJS="$ALL_OBJS $module.o"
done

# Link all modules together
# Note: DATA segment will follow code, not at fixed address
# TODO: Use section directives for proper DATA placement at $DATA_ORG
echo ""
echo "Linking all modules at $CODE_ORG..."
z88dk-z80asm -b -m \
    -o"$OUTPUT_NAME.bin" \
    -r$CODE_ORG \
    $ALL_OBJS

# Report size
BIN_SIZE=$(wc -c < "$OUTPUT_NAME.bin" | tr -d ' ')

echo ""
echo "Build complete:"
echo "  Binary: $OUTPUT_NAME.bin ($BIN_SIZE bytes at $CODE_ORG)"
echo ""
echo "Note: DATA segment follows code; not at fixed address $DATA_ORG"
echo "See map file: $OUTPUT_NAME.map"

# Compare with reference if available
REF_BIN="../bin/$TARGET/BBCBASIC.COM"
if [ -f "$REF_BIN" ]; then
    REF_SIZE=$(wc -c < "$REF_BIN" | tr -d ' ')
    echo ""
    echo "Reference binary: $REF_SIZE bytes"
fi
