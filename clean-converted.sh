#!/usr/bin/env bash

# Remove converted source files and their direct build derivatives
# Usage: ./clean-converted.sh
#
# Removes:
#   - .asm files in src/ (converted from .Z80 by convert.sh)
#   - .asm files copied by convert.sh into target directories
#   - .o and .lis files derived from converted sources
#   - Hex dumps of reference binaries
#
# Does NOT remove:
#   - Other build outputs (.bin, .map, .hex) - use per-target clean.sh for those

set -e

SRC_DIR="src"

# Modules copied from src/ to each target by convert.sh
CPM_MODULES="DIST MAIN EXEC EVAL ASMB MATH HOOK CMOS DATA"
ACORN_MODULES="MAIN EXEC EVAL ASMB MATH ACORN AMOS DATA"

count=0

# Clean converted .asm files from src/
for file in "$SRC_DIR"/*.asm; do
    if [ -f "$file" ]; then
        rm -f "$file"
        count=$((count + 1))
    fi
done

# Clean copied .asm files and their .o/.lis derivatives from target directories
clean_target() {
    local dir="$1"
    local modules="$2"
    for module in $modules; do
        for ext in asm o lis; do
            if [ -f "$dir/$module.$ext" ]; then
                rm -f "$dir/$module.$ext"
                count=$((count + 1))
            fi
        done
    done
}

clean_target "targets/cpm" "$CPM_MODULES"
clean_target "targets/acorn" "$ACORN_MODULES"

# Clean hex dumps of reference binaries
for hex_file in bin/cpm/BBCBASIC.hex bin/acorn/BBCBASIC.hex; do
    if [ -f "$hex_file" ]; then
        rm -f "$hex_file"
        count=$((count + 1))
    fi
done

if [ "$count" -gt 0 ]; then
    echo "Removed $count file(s)"
else
    echo "Nothing to clean"
fi
