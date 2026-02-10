#!/usr/bin/env bash

# Build BBC BASIC Z80 (Acorn tube target)
# Usage: cd build/acorn && ./build.sh
#
# Output: bbcbasic.{bin,hex,map}
#
# Requires: z88dk with z88dk-z80asm
# Before first use, run: ../../convert.sh

set -e
cd "$(dirname "$0")"

MODULES="MAIN EXEC EVAL ASMB MATH ACORN AMOS DATA"
OUTPUT_NAME="bbcbasic"
CODE_ORG="0x0100"
DATA_ORG="0x4C00"

echo "Building BBC BASIC Z80 (acorn)"
echo "=============================="

if [ ! -f "MAIN.asm" ]; then
    echo "Error: Converted source files not found."
    echo "Run ../../convert.sh first."
    exit 1
fi

rm -f *.o *.lis

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

ALL_OBJS=""
for module in $MODULES; do
    ALL_OBJS="$ALL_OBJS $module.o"
done

# Link all modules together
# DATA section is placed at DATA_ORG via section directives
echo ""
echo "Linking all modules at $CODE_ORG..."
z88dk-z80asm -b -m \
    -o"$OUTPUT_NAME.bin" \
    -r$CODE_ORG \
    $ALL_OBJS

rm -f "${OUTPUT_NAME}_data.bin"

EXPECTED_SIZE=$(( DATA_ORG - CODE_ORG ))
BIN_SIZE=$(wc -c < "$OUTPUT_NAME.bin" | tr -d ' ')

if [ "$BIN_SIZE" -lt "$EXPECTED_SIZE" ]; then
    PAD_SIZE=$(( EXPECTED_SIZE - BIN_SIZE ))
    dd if=/dev/zero bs=1 count=$PAD_SIZE >> "$OUTPUT_NAME.bin" 2>/dev/null
    echo "  Padded $PAD_SIZE bytes to reach $DATA_ORG"
    BIN_SIZE=$(wc -c < "$OUTPUT_NAME.bin" | tr -d ' ')
fi

xxd "$OUTPUT_NAME.bin" > "$OUTPUT_NAME.hex"

echo ""
echo "Build complete:"
echo "  Binary: $OUTPUT_NAME.bin ($BIN_SIZE bytes at $CODE_ORG)"
echo "  Hex:    $OUTPUT_NAME.hex"
echo "  Map:    $OUTPUT_NAME.map"

REF_BIN="../../bin/acorn/BBCBASIC.COM"
if [ -f "$REF_BIN" ]; then
    REF_SIZE=$(wc -c < "$REF_BIN" | tr -d ' ')
    echo ""
    echo "Reference binary: $REF_SIZE bytes"
    if [ "$BIN_SIZE" -eq "$REF_SIZE" ]; then
        echo "  Size: MATCH"
        if cmp -s "$OUTPUT_NAME.bin" "$REF_BIN"; then
            echo "  Content: IDENTICAL"
        else
            DIFF_COUNT=$(cmp -l "$OUTPUT_NAME.bin" "$REF_BIN" | wc -l | tr -d ' ')
            echo "  Content: $DIFF_COUNT bytes differ"
        fi
    else
        echo "  Size: MISMATCH (build=$BIN_SIZE, reference=$REF_SIZE)"
    fi
fi
