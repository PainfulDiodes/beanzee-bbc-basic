#!/usr/bin/env bash

# Translate CP/M assembler directives to z88dk syntax
# Usage: ./convert.sh
#
# Copies .Z80 files from src/ to build/ with .asm extension, converting:
#   GLOBAL -> PUBLIC (for modular linking)
#   EXTRN  -> EXTERN (for modular linking)
#   TITLE  -> ; TITLE (commented out)
#   ASEG   -> ; ASEG (commented out)
#   ORG    -> ; ORG (commented out, linker controls origin)
#   END    -> ; END (commented out, not needed)
#   DEFM 'text' -> DEFM "text" (z88dk string syntax)
#   IF $ GT -> ; IF $ GT (commented out, size checks)
#   ERROR  -> ; ERROR (commented out, assembler messages)
#   Character expressions converted to numeric values
#
# EQU definitions are left intact - each module is assembled independently
# so duplicate definitions across modules don't conflict.
#
# Original src/ files are preserved unchanged.

set -e

SRC_DIR="src"
BUILD_DIR="build"

echo "Translating CP/M directives to z88dk syntax"
echo "============================================"

# Create build directory for converted files
mkdir -p "$BUILD_DIR"

# Process each .Z80 file
for file in "$SRC_DIR"/*.Z80; do
    filename=$(basename "$file" .Z80)
    echo "Processing $filename..."

    # Copy original to build directory with .asm extension
    cp "$file" "$BUILD_DIR/$filename.asm"

    # Apply transformations to asm file
    # Note: Using temp file for portability (BSD sed vs GNU sed)
    temp_file=$(mktemp)

    sed \
        -e 's/^\([[:space:]]*\)GLOBAL[[:space:]]/\1PUBLIC /g' \
        -e 's/^\([[:space:]]*\)EXTRN[[:space:]]/\1EXTERN /g' \
        -e 's/^\([[:space:]]*\)TITLE[[:space:]]/\1; TITLE /g' \
        -e 's/^\([[:space:]]*\)ASEG$/\1; ASEG/g' \
        -e 's/^\([[:space:]]*\)ORG[[:space:]]/\1; ORG /g' \
        -e 's/^\([[:space:]]*\)END$/\1; END/g' \
        -e 's/^\([[:space:]]*\)IF[[:space:]]*\$[[:space:]]*GT/\1; IF $ GT/g' \
        -e 's/^\([[:space:]]*\)ERROR[[:space:]]/\1; ERROR /g' \
        -e 's/^\([[:space:]]*\)ENDIF$/\1; ENDIF/g' \
        -e 's/^\([^:]*:\)[[:space:]]*END$/\1 ; END/g' \
        -e 's/^\([[:space:]]*\)END[[:space:]]/\1; END /g' \
        -e "s/DEFM[[:space:]]*'\"'/DEFB 22H\t; double-quote char/g" \
        -e "s/''''/27H/g" \
        -e "s/''/@@APOS@@/g" \
        -e "s/DEFM[[:space:]]*'\([^']*\)'/DEFM \"\1\"/g" \
        -e "s/@@APOS@@/'/g" \
        -e "s/DEFB[[:space:]]*'\([^']*\)\$'/DEFB \"\1\$\"/g" \
        -e "s/'G' AND 1FH/07H/g" \
        -e "s/'O' AND 1FH/0FH/g" \
        -e "s/'F' AND 1FH/06H/g" \
        -e "s/'N' AND 1FH/0EH/g" \
        -e "s/'X' AND 1FH/18H/g" \
        -e "s/'U' AND 1FH/15H/g" \
        -e "s/'J' AND 1FH/0AH/g" \
        -e "s/'L' AND 1FH/0CH/g" \
        -e "s/'R' AND 1FH/12H/g" \
        -e "s/'Q' AND 1FH/11H/g" \
        -e "s/'S' AND 1FH/13H/g" \
        -e "s/'P' AND 1FH/10H/g" \
        -e "s/'+' AND 0FH/0BH/g" \
        -e "s/'\*' AND 0FH/0AH/g" \
        -e "s/'\\\\'/5CH/g" \
        -e "s/TDEF AND 7FH/5DH/g" \
        "$BUILD_DIR/$filename.asm" > "$temp_file"

    mv "$temp_file" "$BUILD_DIR/$filename.asm"
done

# Post-conversion fix for DIST.asm
# Replace ORG 1F0H with DEFS padding to reach offset 0xF0 within module
# (DIST module linked at 0x100, so offset 0xF0 = address 0x1F0)
if [ -f "$BUILD_DIR/DIST.asm" ]; then
    echo "Applying DIST.asm modular build fix..."
    sed -i.bak \
        -e 's/^[[:space:]]*; ORG 1F0H$/\tDEFS 0F0H - $, 0\t; Pad to offset 0xF0 (address 0x1F0 when linked at 0x100)/' \
        "$BUILD_DIR/DIST.asm"
    rm -f "$BUILD_DIR/DIST.asm.bak"
fi

echo ""
echo "Translation complete."
echo "Converted files saved to: $BUILD_DIR/"
echo ""
echo "To build: build/build.sh [cpm|acorn]"
