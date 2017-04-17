; ---------------------------
; Interrupts Service Routines
; ---------------------------
;
#ifndef ISR_INC
#define ISR_INC
#ifdef  ISR_ASM
#define ExtSymbol   global
#else
#define ExtSymbol   extern
#endif
;
; Declare the public symbols
;
    ExtSymbol   INTERRUPT

; end of public symbols
#undefine ExtSymbol

;
; 
;

#endif