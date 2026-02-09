#!/usr/bin/env bash

# z88dk modular build script for BBC BASIC Z80
# Usage:
#   cd build && ./build.sh             # Build CP/M version (default)
#   cd build && ./build.sh cpm         # Build CP/M version
#   cd build && ./build.sh acorn       # Build Acorn tube version
#
# Output: build/<target>/bbcbasic.{bin,hex,map}
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
        CODE_ORG="0x0100"
        DATA_ORG="0x4B00"
        ;;
    acorn)
        MODULES="MAIN EXEC EVAL ASMB MATH ACORN AMOS DATA"
        CODE_ORG="0x0100"
        DATA_ORG="0x4C00"
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Usage: $0 [cpm|acorn]"
        exit 1
        ;;
esac

OUTPUT_NAME="bbcbasic"
TARGET_DIR="$TARGET"
mkdir -p "$TARGET_DIR"

echo "Building BBC BASIC Z80 ($TARGET) - Modular Build"
echo "================================================="

# Check converted source files exist
if [ ! -f "MAIN.asm" ]; then
    echo "Error: Converted source files not found."
    echo "Run ./convert.sh first to convert source files."
    exit 1
fi

# Clean previous intermediate build artifacts
rm -f *.o *.lis

# Assemble each module to object file
echo ""
echo "Assembling modules..."
for module in $MODULES; do
    if [ ! -f "$module.asm" ]; then
        echo "Error: $module.asm not found"
        exit 1
    fi
    EXTRA_FLAGS=""
    if [ "$module" = "DATA" ]; then
        EXTRA_FLAGS="-DDATA_ORG=$DATA_ORG"
    fi
    echo "  $module.asm -> $module.o"
    z88dk-z80asm -l -m $EXTRA_FLAGS -o"$module.o" "$module.asm"
done

# Build object file list for linking
# All modules linked together; DATA follows code
ALL_OBJS=""
for module in $MODULES; do
    ALL_OBJS="$ALL_OBJS $module.o"
done

# Link all modules together
# DATA section is placed at DATA_ORG via section directives
echo ""
echo "Linking all modules at $CODE_ORG..."
z88dk-z80asm -b -m \
    -o"$TARGET_DIR/$OUTPUT_NAME.bin" \
    -r$CODE_ORG \
    $ALL_OBJS

# Remove the DATA section binary (not needed in output)
rm -f "$TARGET_DIR/${OUTPUT_NAME}_data.bin"

# Pad code binary to match reference size
# Reference binary spans from CODE_ORG to DATA_ORG (exclusive)
EXPECTED_SIZE=$(( DATA_ORG - CODE_ORG ))
BIN_SIZE=$(wc -c < "$TARGET_DIR/$OUTPUT_NAME.bin" | tr -d ' ')

if [ "$BIN_SIZE" -lt "$EXPECTED_SIZE" ]; then
    PAD_SIZE=$(( EXPECTED_SIZE - BIN_SIZE ))
    dd if=/dev/zero bs=1 count=$PAD_SIZE >> "$TARGET_DIR/$OUTPUT_NAME.bin" 2>/dev/null
    echo "  Padded $PAD_SIZE bytes to reach $DATA_ORG"
    BIN_SIZE=$(wc -c < "$TARGET_DIR/$OUTPUT_NAME.bin" | tr -d ' ')
fi

# Create hex dump of build binary
xxd "$TARGET_DIR/$OUTPUT_NAME.bin" > "$TARGET_DIR/$OUTPUT_NAME.hex"

echo ""
echo "Build complete:"
echo "  Binary: $TARGET_DIR/$OUTPUT_NAME.bin ($BIN_SIZE bytes at $CODE_ORG)"
echo "  Hex:    $TARGET_DIR/$OUTPUT_NAME.hex"
echo "  Map:    $TARGET_DIR/$OUTPUT_NAME.map"

# Compare with reference binary
REF_BIN="../bin/$TARGET/BBCBASIC.COM"
if [ -f "$REF_BIN" ]; then
    REF_SIZE=$(wc -c < "$REF_BIN" | tr -d ' ')
    echo ""
    echo "Reference binary: $REF_SIZE bytes"
    if [ "$BIN_SIZE" -eq "$REF_SIZE" ]; then
        echo "  Size: MATCH"
        if cmp -s "$TARGET_DIR/$OUTPUT_NAME.bin" "$REF_BIN"; then
            echo "  Content: IDENTICAL"
        else
            DIFF_COUNT=$(cmp -l "$TARGET_DIR/$OUTPUT_NAME.bin" "$REF_BIN" | wc -l | tr -d ' ')
            echo "  Content: $DIFF_COUNT bytes differ"
        fi
    else
        echo "  Size: MISMATCH (build=$BIN_SIZE, reference=$REF_SIZE)"
    fi
fi
