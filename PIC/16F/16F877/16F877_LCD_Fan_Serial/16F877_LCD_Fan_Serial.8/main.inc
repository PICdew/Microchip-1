        list    n=0, c=250      ; No page breaks, support long lines in list file
        list    r=dec
        errorlevel -302         ; Suppress not in bank zero warning
#ifdef __16F877A
  list    p=16F877A       ; Select PIC16F877A as target device
  #include <p16f877A.inc>
#else 
  #ifdef __16F877
    list    p=16F877        ; Select PIC16F877  as target device
    #include <p16f877.inc>
  #else 
    error Code buils only for PIC16F877 or PIC16F877A
  #endif
#endif
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
; Declare the public symbols
;
    ExtSymbol   main
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
;
; Define the system oscillator frequency and instruction cycle frequency
;
#define FSYS (d'8000000')
#define FCYC (FSYS/d'4')

#endif