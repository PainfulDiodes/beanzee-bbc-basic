; BBC BASIC Z80 - CP/M Build
; Entry point wrapper for z88dk include-based build
;
; This file includes all modules in the correct order for CP/M target.
; Module order matches original MAKE.SUB link order.
;
; Before using: run translate-directives.sh to convert GLOBAL/EXTRN
; or manually remove them (not needed with include approach).

IFDEF BASIC_ORG
    ORG BASIC_ORG
ELSE
    ORG 0x0100
ENDIF

; CP/M target flag
CPM_TARGET  EQU 1
ACORN_TARGET EQU 0

; Include modules in link order from original MAKE.SUB:
; link bbcbasic=dist,main,exec,eval,asmb,math,hook,cmos,/p:4B00,data

include "repo/src/DIST.Z80"
include "repo/src/MAIN.Z80"
include "repo/src/EXEC.Z80"
include "repo/src/EVAL.Z80"
include "repo/src/ASMB.Z80"
include "repo/src/MATH.Z80"
include "repo/src/HOOK.Z80"
include "repo/src/CMOS.Z80"

; DATA module at separate address (0x4B00 in original)
; Note: May need ORG directive adjustment or SECTION for z88dk
ORG 0x4B00
include "repo/src/DATA.Z80"
