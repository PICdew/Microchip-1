; 
; File: init.asm
; Target: PIC16F877A or PIC16F877
; IDE: MPLAB v8.92
; Compiler: MPASMWIN v5.51
;
; -------------------------
; Initialization 
; -------------------------
#define INIT_ASM
#include "main.inc"
;
; Configuration words.
; Define these in just one file.
;
    __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

;**********************************************************************
RESET_VECTOR CODE 0x000         ; processor reset vector
    nop                         ; ICD2 needs this
    pagesel start
    goto    start               ; begin PIC initialization


;------------------------------------------------------------------------
START_CODE CODE
start:
    clrf    INTCON              ; Disable all interrupt sources
    banksel BANK1
    clrf    PIE1
    clrf    PIE2
    
    movlw   b'11111111'         ;
    movwf   OPTION_REG
            
    movlw   b'11111111'         ; 
    movwf   TRISA           
            
    movlw   b'11111111'         ; 
    movwf   TRISB           
            
    movlw   b'11111111'         ; 
    movwf   TRISC           
    
    movlw   b'11111111'         ; 
    movwf   TRISD
#ifdef __16F877A
    ; disable comparators
    movlw   b'00000111'
    movwf   CMCON
#endif
    ; Set all ADC inputs for digital I/O
    movlw   b'00000110'
    movwf   ADCON1
    
    banksel BANK0
    clrf    TMR0
    pagesel main
    goto    main

    END
