#!/usr/bin/env bash

# Translate CP/M assembler directives to z88dk syntax
# Usage: ./convert-source.sh
#
# Copies .Z80 files from src/ to asm/ with .asm extension, converting:
#   GLOBAL -> PUBLIC
#   EXTRN  -> EXTERN
#   TITLE  -> ; TITLE (commented out)
#   ASEG   -> ; ASEG (commented out, z88dk handles segments differently)
#
# Original src/ files are preserved unchanged.

set -e

SRC_DIR="src"
ASM_DIR="asm"

echo "Translating CP/M directives to z88dk syntax"
echo "============================================"

# Create asm directory for converted files
mkdir -p "$ASM_DIR"

# Process each .Z80 file
for file in "$SRC_DIR"/*.Z80; do
    filename=$(basename "$file" .Z80)
    echo "Processing $filename..."

    # Copy original to asm directory with .asm extension
    cp "$file" "$ASM_DIR/$filename.asm"

    # Apply transformations to asm file
    # Note: Using temp file for portability (BSD sed vs GNU sed)
    temp_file=$(mktemp)

    sed -e 's/^\([[:space:]]*\)GLOBAL\([[:space:]]\)/\1PUBLIC\2/g' \
        -e 's/^\([[:space:]]*\)EXTRN\([[:space:]]\)/\1EXTERN\2/g' \
        -e 's/^\([[:space:]]*\)TITLE\([[:space:]]\)/\1; TITLE\2/g' \
        -e 's/^\([[:space:]]*\)ASEG$/\1; ASEG/g' \
        "$ASM_DIR/$filename.asm" > "$temp_file"

    mv "$temp_file" "$ASM_DIR/$filename.asm"
done

echo ""
echo "Translation complete."
echo "Converted files saved to: $ASM_DIR/"
echo ""
echo "Manual review recommended for:"
echo "  - ORG directives (may need SECTION instead)"
echo "  - END directives (z88dk typically doesn't need them)"
echo "  - Any conditional assembly (IF/ENDIF)"
