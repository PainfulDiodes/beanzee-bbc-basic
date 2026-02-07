; BBC BASIC Z80 - Acorn Tube Build
; Entry point wrapper for z88dk include-based build
;
; This file includes all modules in the correct order for Acorn target.
; Module order matches original MAKE.SUB link order.
;
; Before using: run translate-directives.sh to convert GLOBAL/EXTRN
; or manually remove them (not needed with include approach).

IFDEF BASIC_ORG
    ORG BASIC_ORG
ELSE
    ORG 0x0100
ENDIF

; Acorn target flag
CPM_TARGET  EQU 0
ACORN_TARGET EQU 1

; Include modules in link order from original MAKE.SUB:
; link bbctube=/p:0100,main,exec,eval,asmb,math,acorn,amos,/p:4C00,data
;
; Note: Acorn build doesn't include DIST (has different entry),
; and uses ACORN+AMOS instead of HOOK+CMOS

include "repo/src/MAIN.Z80"
include "repo/src/EXEC.Z80"
include "repo/src/EVAL.Z80"
include "repo/src/ASMB.Z80"
include "repo/src/MATH.Z80"
include "repo/src/ACORN.Z80"
include "repo/src/AMOS.Z80"

; DATA module at separate address (0x4C00 in original)
ORG 0x4C00
include "repo/src/DATA.Z80"
