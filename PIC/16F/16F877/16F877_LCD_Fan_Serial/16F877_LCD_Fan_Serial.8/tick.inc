; ---------------------------
; System Tick
; ---------------------------
;
#ifndef TICK_INC
#define TICK_INC
#ifdef  TICK_ASM
#define ExtSymbol   global
#else
#define ExtSymbol   extern
#endif
;
; Declare the public symbols
;
    ExtSymbol   Tick_Init
    ExtSymbol   SystemTickTimeout

; end of public symbols
#undefine ExtSymbol

;
; 
;

#endif