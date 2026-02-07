; BBC BASIC Z80 - Acorn Tube Build
; Entry point wrapper for z88dk include-based build
;
; This file includes all modules in the correct order for Acorn target.
; Module order matches original MAKE.SUB link order.
;
; Before using: run convert-source.sh to create asm/ directory
; with converted source files.

IFDEF BASIC_ORG
    ORG BASIC_ORG
ELSE
    ORG 0x0100
ENDIF

; Acorn target flag
CPM_TARGET  EQU 0
ACORN_TARGET EQU 1

; Shared constants (must be included before modules)
include "asm/constants.inc"

; Include modules in link order from original MAKE.SUB:
; link bbctube=/p:0100,main,exec,eval,asmb,math,acorn,amos,/p:4C00,data
;
; Note: Acorn build doesn't include DIST (has different entry),
; and uses ACORN+AMOS instead of HOOK+CMOS

include "asm/MAIN.asm"
include "asm/EXEC.asm"
include "asm/EVAL.asm"
include "asm/ASMB.asm"
include "asm/MATH.asm"
include "asm/ACORN.asm"
include "asm/AMOS.asm"

; DATA module at separate address (0x4C00 in original)
ORG 0x4C00
include "asm/DATA.asm"
