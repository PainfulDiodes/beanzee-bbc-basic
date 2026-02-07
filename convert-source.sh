#!/usr/bin/env bash

# Translate CP/M assembler directives to z88dk syntax
# Usage: ./convert-source.sh
#
# Copies .Z80 files from src/ to asm/ with .asm extension, converting:
#   GLOBAL -> PUBLIC
#   EXTRN  -> EXTERN
#   TITLE  -> ; TITLE (commented out)
#   ASEG   -> ; ASEG (commented out)
#   ORG    -> ; ORG (commented out, wrapper controls origin)
#   END    -> ; END (commented out, not needed with includes)
#   DEFM 'text' -> DEFM "text" (z88dk string syntax)
#   IF $ GT -> ; IF $ GT (commented out, size checks)
#   ERROR  -> ; ERROR (commented out, assembler messages)
#   Character expressions converted to numeric values
#
# Original src/ files are preserved unchanged.

set -e

SRC_DIR="src"
ASM_DIR="asm"

echo "Translating CP/M directives to z88dk syntax"
echo "============================================"

# Create asm directory for converted files
mkdir -p "$ASM_DIR"

# Create shared constants file
cat > "$ASM_DIR/constants.inc" << 'CONSTANTS'
; BBC BASIC Z80 - Shared Constants
; Extracted from source modules to avoid duplicate definitions

; ASCII control characters
LF      EQU     0AH
CR      EQU     0DH
ESC     EQU     1BH
BEL     EQU     7
BS      EQU     8
HT      EQU     9
VT      EQU     0BH
; Note: DEL conflicts with label in MAIN.Z80, not included

; CP/M system addresses
; Note: BDOS conflicts with label in DIST.Z80, not included
FCB     EQU     5CH
DSKBUF  EQU     80H
FCBSIZ  EQU     128+36+2

; Token values
TAND    EQU     80H
TOR     EQU     84H
TBY     EQU     0FH
TERROR  EQU     85H
TLINE   EQU     86H
TOFF    EQU     87H
TSTEP   EQU     88H
TSPC    EQU     89H
TTAB    EQU     8AH
TELSE   EQU     8BH
TTHEN   EQU     8CH
TLINO   EQU     8DH
TTO     EQU     0B8H
TCASE   EQU     0C8H
TWHILE  EQU     0C7H
TWHEN   EQU     0C9H
TOF     EQU     0CAH
TENDCASE EQU    0CBH
TOTHERWISE EQU  0CCH
TENDIF  EQU     0CDH
TENDWHILE EQU   0CEH
TCALL   EQU     0D6H
TDATA   EQU     0DCH
TDEF    EQU     0DDH
TDIM    EQU     0DEH
TEND    EQU     0E0H
TFOR    EQU     0E3H
TGOSUB  EQU     0E4H
TGOTO   EQU     0E5H
TIF     EQU     0E7H
TLOCAL  EQU     0EAH
TMODE   EQU     0EBH
TNEXT   EQU     0EDH
TON     EQU     0EEH
TPROC   EQU     0F2H
TREM    EQU     0F4H
TREPEAT EQU     0F5H
TREPORT EQU     0F6H
TRESTORE EQU    0F7H
TRETURN EQU     0F8H
TSTOP   EQU     0FAH
TTRACE  EQU     0FCH
TUNTIL  EQU     0FDH
TWIDTH  EQU     0FEH
TEXIT   EQU     10H

; Error codes
BADOP   EQU     1
DIVBY0  EQU     18
; Note: TOOBIG conflicts with label in MAIN.Z80, not included
NGROOT  EQU     21
LOGRNG  EQU     22
ACLOST  EQU     23
EXPRNG  EQU     24
CONSTANTS

# Process each .Z80 file
for file in "$SRC_DIR"/*.Z80; do
    filename=$(basename "$file" .Z80)
    echo "Processing $filename..."

    # Copy original to asm directory with .asm extension
    cp "$file" "$ASM_DIR/$filename.asm"

    # Apply transformations to asm file
    # Note: Using temp file for portability (BSD sed vs GNU sed)
    temp_file=$(mktemp)

    sed \
        -e 's/^\([[:space:]]*\)GLOBAL[[:space:]]/\1; PUBLIC /g' \
        -e 's/^\([[:space:]]*\)EXTRN[[:space:]]/\1; EXTERN /g' \
        -e 's/^\([[:space:]]*\)PUBLIC[[:space:]]/\1; PUBLIC /g' \
        -e 's/^\([[:space:]]*\)EXTERN[[:space:]]/\1; EXTERN /g' \
        -e 's/^\([[:space:]]*\)TITLE[[:space:]]/\1; TITLE /g' \
        -e 's/^\([[:space:]]*\)ASEG$/\1; ASEG/g' \
        -e 's/^\([[:space:]]*\)ORG[[:space:]]/\1; ORG /g' \
        -e 's/^\([[:space:]]*\)END$/\1; END/g' \
        -e 's/^\([[:space:]]*\)IF[[:space:]]*\$[[:space:]]*GT/\1; IF $ GT/g' \
        -e 's/^\([[:space:]]*\)ERROR[[:space:]]/\1; ERROR /g' \
        -e 's/^\([[:space:]]*\)ENDIF$/\1; ENDIF/g' \
        -e 's/^\([^:]*:\)[[:space:]]*END$/\1 ; END/g' \
        -e 's/^\([[:space:]]*\)END[[:space:]]/\1; END /g' \
        -e "s/DEFM[[:space:]]*'\([^']*\)'/DEFM \"\1\"/g" \
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
        -e 's/^LF[[:space:]]*EQU/; LF EQU/' \
        -e 's/^CR[[:space:]]*EQU/; CR EQU/' \
        -e 's/^ESC[[:space:]]*EQU/; ESC EQU/' \
        -e 's/^BEL[[:space:]]*EQU/; BEL EQU/' \
        -e 's/^BS[[:space:]]*EQU/; BS EQU/' \
        -e 's/^HT[[:space:]]*EQU/; HT EQU/' \
        -e 's/^VT[[:space:]]*EQU/; VT EQU/' \
        -e 's/^FCB[[:space:]]*EQU/; FCB EQU/' \
        -e 's/^DSKBUF[[:space:]]*EQU/; DSKBUF EQU/' \
        -e 's/^FCBSIZ[[:space:]]*EQU/; FCBSIZ EQU/' \
        -e 's/^TAND[[:space:]]*EQU/; TAND EQU/' \
        -e 's/^TOR[[:space:]]*EQU/; TOR EQU/' \
        -e 's/^TBY[[:space:]]*EQU/; TBY EQU/' \
        -e 's/^TERROR[[:space:]]*EQU/; TERROR EQU/' \
        -e 's/^TLINE[[:space:]]*EQU/; TLINE EQU/' \
        -e 's/^TOFF[[:space:]]*EQU/; TOFF EQU/' \
        -e 's/^TSTEP[[:space:]]*EQU/; TSTEP EQU/' \
        -e 's/^TSPC[[:space:]]*EQU/; TSPC EQU/' \
        -e 's/^TTAB[[:space:]]*EQU/; TTAB EQU/' \
        -e 's/^TELSE[[:space:]]*EQU/; TELSE EQU/' \
        -e 's/^TTHEN[[:space:]]*EQU/; TTHEN EQU/' \
        -e 's/^TLINO[[:space:]]*EQU/; TLINO EQU/' \
        -e 's/^TTO[[:space:]]*EQU/; TTO EQU/' \
        -e 's/^TCASE[[:space:]]*EQU/; TCASE EQU/' \
        -e 's/^TWHILE[[:space:]]*EQU/; TWHILE EQU/' \
        -e 's/^TWHEN[[:space:]]*EQU/; TWHEN EQU/' \
        -e 's/^TOF[[:space:]]*EQU/; TOF EQU/' \
        -e 's/^TENDCASE[[:space:]]*EQU/; TENDCASE EQU/' \
        -e 's/^TOTHERWISE[[:space:]]*EQU/; TOTHERWISE EQU/' \
        -e 's/^TENDIF[[:space:]]*EQU/; TENDIF EQU/' \
        -e 's/^TENDWHILE[[:space:]]*EQU/; TENDWHILE EQU/' \
        -e 's/^TCALL[[:space:]]*EQU/; TCALL EQU/' \
        -e 's/^TDATA[[:space:]]*EQU/; TDATA EQU/' \
        -e 's/^TDEF[[:space:]]*EQU/; TDEF EQU/' \
        -e 's/^TDIM[[:space:]]*EQU/; TDIM EQU/' \
        -e 's/^TEND[[:space:]]*EQU/; TEND EQU/' \
        -e 's/^TFOR[[:space:]]*EQU/; TFOR EQU/' \
        -e 's/^TGOSUB[[:space:]]*EQU/; TGOSUB EQU/' \
        -e 's/^TGOTO[[:space:]]*EQU/; TGOTO EQU/' \
        -e 's/^TIF[[:space:]]*EQU/; TIF EQU/' \
        -e 's/^TLOCAL[[:space:]]*EQU/; TLOCAL EQU/' \
        -e 's/^TMODE[[:space:]]*EQU/; TMODE EQU/' \
        -e 's/^TNEXT[[:space:]]*EQU/; TNEXT EQU/' \
        -e 's/^TON[[:space:]]*EQU/; TON EQU/' \
        -e 's/^TPROC[[:space:]]*EQU/; TPROC EQU/' \
        -e 's/^TREM[[:space:]]*EQU/; TREM EQU/' \
        -e 's/^TREPEAT[[:space:]]*EQU/; TREPEAT EQU/' \
        -e 's/^TREPORT[[:space:]]*EQU/; TREPORT EQU/' \
        -e 's/^TRESTORE[[:space:]]*EQU/; TRESTORE EQU/' \
        -e 's/^TRETURN[[:space:]]*EQU/; TRETURN EQU/' \
        -e 's/^TSTOP[[:space:]]*EQU/; TSTOP EQU/' \
        -e 's/^TTRACE[[:space:]]*EQU/; TTRACE EQU/' \
        -e 's/^TUNTIL[[:space:]]*EQU/; TUNTIL EQU/' \
        -e 's/^TWIDTH[[:space:]]*EQU/; TWIDTH EQU/' \
        -e 's/^TEXIT[[:space:]]*EQU/; TEXIT EQU/' \
        -e 's/^BADOP[[:space:]]*EQU/; BADOP EQU/' \
        -e 's/^DIVBY0[[:space:]]*EQU/; DIVBY0 EQU/' \
        -e 's/^NGROOT[[:space:]]*EQU/; NGROOT EQU/' \
        -e 's/^LOGRNG[[:space:]]*EQU/; LOGRNG EQU/' \
        -e 's/^ACLOST[[:space:]]*EQU/; ACLOST EQU/' \
        -e 's/^EXPRNG[[:space:]]*EQU/; EXPRNG EQU/' \
        "$ASM_DIR/$filename.asm" > "$temp_file"

    mv "$temp_file" "$ASM_DIR/$filename.asm"
done

echo ""
echo "Translation complete."
echo "Converted files saved to: $ASM_DIR/"
echo "Shared constants saved to: $ASM_DIR/constants.inc"
echo ""
echo "Manual fixes still required:"
echo "  - Duplicate code labels (COLD, ERROR0-4, CLS, CMDTAB, etc.)"
echo "  - Quote escaping in strings containing quotes"
echo "  - Remaining character expressions"
echo ""
echo "See building-BBCZ80.md for details."
