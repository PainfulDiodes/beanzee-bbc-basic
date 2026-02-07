#!/usr/bin/env bash

# z88dk build script for BBC BASIC Z80
# Usage:
#   ./build-z88dk.sh             # Build CP/M version (default)
#   ./build-z88dk.sh cpm         # Build CP/M version
#   ./build-z88dk.sh acorn       # Build Acorn tube version
#
# Requires: z88dk with z88dk-z80asm
#
# Note: Source files need directive translation before first use:
#   GLOBAL -> PUBLIC
#   EXTRN  -> EXTERN
#   TITLE  -> ; TITLE (commented)
#   ASEG   -> removed or use SECTION
#
# See translate-directives.sh for automated conversion.

set -e  # Exit on error

# Configuration
OUTPUT_DIR="output"
SRC_DIR="repo/src"

# Target selection
TARGET="${1:-cpm}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

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

echo "Building BBC BASIC Z80 ($TARGET)"
echo "================================"

# Clean previous build
rm -f "$OUTPUT_DIR"/*.o "$OUTPUT_DIR"/*.bin "$OUTPUT_DIR"/*.map "$OUTPUT_DIR"/*.lis

# Assemble each module
for module in $MODULES; do
    echo "Assembling $module..."
    z88dk-z80asm -l -m "$SRC_DIR/$module.Z80" -o"$OUTPUT_DIR/$module.o"
done

# Link all modules
# Note: z88dk-z80asm links in order specified, DATA module placed at DATA_ORG
echo "Linking..."

# Build the object file list
OBJ_LIST=""
for module in $MODULES; do
    if [ "$module" = "DATA" ]; then
        # DATA module has different origin - handle separately
        continue
    fi
    OBJ_LIST="$OBJ_LIST $OUTPUT_DIR/$module.o"
done

# Link code modules
z88dk-z80asm -b -m \
    -o"$OUTPUT_DIR/$OUTPUT_NAME.bin" \
    --org=$CODE_ORG \
    $OBJ_LIST

# Link DATA module at separate address
z88dk-z80asm -b -m \
    -o"$OUTPUT_DIR/data.bin" \
    --org=$DATA_ORG \
    "$OUTPUT_DIR/DATA.o"

# Create hex dump for inspection
hexdump -C "$OUTPUT_DIR/$OUTPUT_NAME.bin" > "$OUTPUT_DIR/$OUTPUT_NAME.hex"

# Create Intel HEX format for programmers
z88dk-appmake +hex --org $CODE_ORG -b "$OUTPUT_DIR/$OUTPUT_NAME.bin" -o "$OUTPUT_DIR/$OUTPUT_NAME.ihx"

echo ""
echo "Build complete:"
echo "  Binary: $OUTPUT_DIR/$OUTPUT_NAME.bin (code at $CODE_ORG)"
echo "  Data:   $OUTPUT_DIR/data.bin (at $DATA_ORG)"
echo "  Hex:    $OUTPUT_DIR/$OUTPUT_NAME.hex"
echo "  Intel:  $OUTPUT_DIR/$OUTPUT_NAME.ihx"
