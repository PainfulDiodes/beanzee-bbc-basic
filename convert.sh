#!/usr/bin/env bash

# Translate CP/M assembler directives to z88dk syntax
# Usage: ./convert.sh
#
# Copies .Z80 files from src/ to per-target build directories with .asm
# extension, converting:
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

# Target definitions: directory and module list
CPM_DIR="build/cpm"
CPM_MODULES="DIST MAIN EXEC EVAL ASMB MATH HOOK CMOS DATA"

ACORN_DIR="build/acorn"
ACORN_MODULES="MAIN EXEC EVAL ASMB MATH ACORN AMOS DATA"

echo "Translating CP/M directives to z88dk syntax"
echo "============================================"

mkdir -p "$CPM_DIR" "$ACORN_DIR"

# Convert a source file and write to target directory
convert_module() {
    local src_file="$1"
    local dest_file="$2"

    cp "$src_file" "$dest_file"

    # Apply transformations
    # Note: Using temp file for portability (BSD sed vs GNU sed)
    local temp_file
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
        "$dest_file" > "$temp_file"

    mv "$temp_file" "$dest_file"
}

# Check if a module is in a space-separated list
has_module() {
    local module="$1"
    local list="$2"
    for m in $list; do
        if [ "$m" = "$module" ]; then
            return 0
        fi
    done
    return 1
}

# Process each .Z80 file, placing it in the appropriate target directories
for file in "$SRC_DIR"/*.Z80; do
    filename=$(basename "$file" .Z80)

    if has_module "$filename" "$CPM_MODULES"; then
        echo "  $filename -> $CPM_DIR/$filename.asm"
        convert_module "$file" "$CPM_DIR/$filename.asm"
    fi

    if has_module "$filename" "$ACORN_MODULES"; then
        echo "  $filename -> $ACORN_DIR/$filename.asm"
        convert_module "$file" "$ACORN_DIR/$filename.asm"
    fi
done

# Post-conversion fix for DIST.asm (CPM only)
# Replace ORG 1F0H with DEFS padding to reach offset 0xF0 within module
# (DIST module linked at 0x100, so offset 0xF0 = address 0x1F0)
if [ -f "$CPM_DIR/DIST.asm" ]; then
    echo "Applying DIST.asm modular build fix..."
    sed -i.bak \
        -e 's/^[[:space:]]*; ORG 1F0H$/\tDEFS 0F0H - $, 0\t; Pad to offset 0xF0 (address 0x1F0 when linked at 0x100)/' \
        "$CPM_DIR/DIST.asm"
    rm -f "$CPM_DIR/DIST.asm.bak"
fi

# Post-conversion fix for DATA.asm
# Add SECTION and ORG directives so the linker places DATA at a fixed address
# DATA_ORG is defined via -D flag at assembly time (0x4B00 for CPM, 0x4C00 for Acorn)
for target_dir in "$CPM_DIR" "$ACORN_DIR"; do
    if [ -f "$target_dir/DATA.asm" ]; then
        echo "Applying $target_dir/DATA.asm section placement fix..."
        temp_file=$(mktemp)
        {
            echo "    SECTION data"
            echo "    ORG DATA_ORG"
            cat "$target_dir/DATA.asm"
        } > "$temp_file"
        mv "$temp_file" "$target_dir/DATA.asm"
    fi
done

echo ""
echo "Translation complete."
echo "Converted files saved to: $CPM_DIR/ and $ACORN_DIR/"

# Create hex dumps of reference binaries
echo ""
echo "Creating hex dumps of reference binaries..."
for target_dir in bin/cpm bin/acorn; do
    if [ -f "$target_dir/BBCBASIC.COM" ]; then
        xxd "$target_dir/BBCBASIC.COM" > "$target_dir/BBCBASIC.hex"
        echo "  $target_dir/BBCBASIC.COM -> $target_dir/BBCBASIC.hex"
    fi
done

echo ""
echo "To build: build/cpm/build.sh   (CP/M target)"
echo "          build/acorn/build.sh (Acorn tube target)"
