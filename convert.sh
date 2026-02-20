#!/usr/bin/env bash

# Translate CP/M assembler directives to z88dk syntax
# Usage: ./convert.sh
#
# Phase 1: Converts .Z80 files in src/ to .asm files in src/ (one-time)
# Phase 2: Copies converted .asm files to per-target directories
#
# Conversions applied:
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
# Original .Z80 files are preserved unchanged.

set -e

SRC_DIR="src"

# Target definitions: directory and module list
CPM_DIR="targets/cpm"
CPM_MODULES="DIST MAIN EXEC EVAL ASMB MATH HOOK CMOS DATA"

ACORN_DIR="targets/acorn"
ACORN_MODULES="MAIN EXEC EVAL ASMB MATH ACORN AMOS DATA"

echo "Phase 1: Translating CP/M directives to z88dk syntax"
echo "====================================================="

# Convert a .Z80 source file to .asm in the same directory
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

# Convert each .Z80 file in src/ to .asm
for file in "$SRC_DIR"/*.Z80; do
    filename=$(basename "$file" .Z80)
    dest="$SRC_DIR/$filename.asm"
    echo "  $filename.Z80 -> $filename.asm"
    convert_module "$file" "$dest"
done

# DIST.asm fix: replace ORG 1F0H with DEFS padding
# DIST is CPM-only so this is safe to apply in src/
if [ -f "$SRC_DIR/DIST.asm" ]; then
    echo "Applying DIST.asm build fix..."
    temp_file=$(mktemp)
    sed \
        -e 's/^[[:space:]]*; ORG 1F0H$/\tDEFS 0F0H - $, 0\t; Pad to offset 0xF0 (address 0x1F0 when linked at 0x100)/' \
        "$SRC_DIR/DIST.asm" > "$temp_file"
    mv "$temp_file" "$SRC_DIR/DIST.asm"
fi

# DATA.asm fix: prepend SECTION and ORG directives
# DATA_ORG is defined via -D flag at assembly time, so the same text works for all targets
if [ -f "$SRC_DIR/DATA.asm" ]; then
    echo "Applying DATA.asm section placement fix..."
    temp_file=$(mktemp)
    {
        echo "    SECTION data"
        echo "    ORG DATA_ORG"
        cat "$SRC_DIR/DATA.asm"
    } > "$temp_file"
    mv "$temp_file" "$SRC_DIR/DATA.asm"
fi

# MAIN_SM_DSP.asm: display-friendly variant with banner strings ≤20 chars
# for 20-column LCD devices (e.g. HD44780 20x4)
if [ -f "$SRC_DIR/MAIN.asm" ]; then
    echo "Creating MAIN_SM_DSP.asm (small display variant)..."
    temp_file=$(mktemp)
    sed \
        -e 's/DEFM "BBC BASIC (Z80) Version 5\.00  "/DEFM "Z80 BBC BASIC 5.00"/' \
        -e 's/DEFM "(C) Copyright R\.T\.Russell 2025"/DEFM "(C) R.T.Russell\\n2025"/' \
        "$SRC_DIR/MAIN.asm" > "$temp_file"
    mv "$temp_file" "$SRC_DIR/MAIN_SM_DSP.asm"
fi

echo ""
echo "Phase 2: Copying converted files to targets"
echo "============================================"

mkdir -p "$CPM_DIR" "$ACORN_DIR"

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

# Copy converted .asm files to each target directory
for file in "$SRC_DIR"/*.asm; do
    filename=$(basename "$file" .asm)

    if has_module "$filename" "$CPM_MODULES"; then
        echo "  $filename.asm -> $CPM_DIR/"
        cp "$file" "$CPM_DIR/$filename.asm"
    fi

    if has_module "$filename" "$ACORN_MODULES"; then
        echo "  $filename.asm -> $ACORN_DIR/"
        cp "$file" "$ACORN_DIR/$filename.asm"
    fi
done

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
echo "Conversion complete."
echo "To build: targets/cpm/build.sh     (CP/M target)"
echo "          targets/acorn/build.sh   (Acorn tube target)"
