#!/usr/bin/env bash

# Translate CP/M assembler directives to z88dk syntax
# Usage: ./translate-directives.sh
#
# Converts in-place:
#   GLOBAL -> PUBLIC
#   EXTRN  -> EXTERN
#   TITLE  -> ; TITLE (commented out)
#   ASEG   -> ; ASEG (commented out, z88dk handles segments differently)
#
# Creates backups with .bak extension

set -e

SRC_DIR="repo/src"
BACKUP_DIR="repo/src-backup"

echo "Translating CP/M directives to z88dk syntax"
echo "============================================"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Process each .Z80 file
for file in "$SRC_DIR"/*.Z80; do
    filename=$(basename "$file")
    echo "Processing $filename..."

    # Create backup
    cp "$file" "$BACKUP_DIR/$filename"

    # Apply transformations
    # Note: Using temp file for portability (BSD sed vs GNU sed)
    temp_file=$(mktemp)

    sed -e 's/^\([[:space:]]*\)GLOBAL\([[:space:]]\)/\1PUBLIC\2/g' \
        -e 's/^\([[:space:]]*\)EXTRN\([[:space:]]\)/\1EXTERN\2/g' \
        -e 's/^\([[:space:]]*\)TITLE\([[:space:]]\)/\1; TITLE\2/g' \
        -e 's/^\([[:space:]]*\)ASEG$/\1; ASEG/g' \
        "$file" > "$temp_file"

    mv "$temp_file" "$file"
done

echo ""
echo "Translation complete."
echo "Backups saved to: $BACKUP_DIR/"
echo ""
echo "Manual review recommended for:"
echo "  - ORG directives (may need SECTION instead)"
echo "  - END directives (z88dk typically doesn't need them)"
echo "  - Any conditional assembly (IF/ENDIF)"
