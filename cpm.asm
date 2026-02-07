; BBC BASIC Z80 - CP/M Build
; Entry point wrapper for z88dk include-based build
;
; This file includes all modules in the correct order for CP/M target.
; Module order matches original MAKE.SUB link order.
;
; Before using: run convert-source.sh to create asm/ directory
; with converted source files.

IFDEF BASIC_ORG
    ORG BASIC_ORG
ELSE
    ORG 0x0100
ENDIF

; CP/M target flag
CPM_TARGET  EQU 1
ACORN_TARGET EQU 0

; Shared constants (must be included before modules)
include "asm/constants.inc"

; Include modules in link order from original MAKE.SUB:
; link bbcbasic=dist,main,exec,eval,asmb,math,hook,cmos,/p:4B00,data

include "asm/DIST.asm"
include "asm/MAIN.asm"
include "asm/EXEC.asm"
include "asm/EVAL.asm"
include "asm/ASMB.asm"
include "asm/MATH.asm"
include "asm/HOOK.asm"
include "asm/CMOS.asm"

; DATA module at separate address (0x4B00 in original)
ORG 0x4B00
include "asm/DATA.asm"
