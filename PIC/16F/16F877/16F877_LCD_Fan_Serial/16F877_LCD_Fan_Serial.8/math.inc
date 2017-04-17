; ---------------------------
; MATH Routines
; ---------------------------
;
#ifndef MATH_INC
#define MATH_INC
#ifdef  MATH_ASM
#define ExtSymbol   global
#else
#define ExtSymbol   extern
#endif
;
; Declare the public symbols
;
    ExtSymbol   A_reg
    ExtSymbol   B_reg
    ExtSymbol   D_reg
    ExtSymbol   uMutiply_16x16
    ExtSymbol   Bin2BCD

; end of public symbols
#undefine ExtSymbol

;
; 
;

#endif