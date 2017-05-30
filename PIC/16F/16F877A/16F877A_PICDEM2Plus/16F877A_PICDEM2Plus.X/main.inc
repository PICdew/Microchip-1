        list    p=16F877A       ; Select PIC16F877A as target device
        list    n=0, c=250      ; No page breaks, support long lines in list file
        list    r=dec
        errorlevel -302         ; Suppress not in bank zero warning
#include <p16f877A.inc>
; -------------------------
; Main application
; -------------------------
#ifndef MAIN_INC
#define MAIN_INC
#ifdef  MAIN_ASM
#define ExtSymbol   global
#else
#define ExtSymbol   extern
#endif
;
; Define string selectors
;
#define BLANKLINE 0
#define MESSAGE4 1
#define MESSAGE5 2
#define MESSAGE6 3
;
; Declare the public symbols
;
    ExtSymbol   main
    ExtSymbol   TableOfStringPointers
;
; end of public symbols
#undefine ExtSymbol

;
; Define macros to help with
; bank selection
;
#define BANK0  (h'000')
#define BANK1  (h'080')
#define BANK2  (h'100')
#define BANK3  (h'180')

#endif