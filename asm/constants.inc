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
