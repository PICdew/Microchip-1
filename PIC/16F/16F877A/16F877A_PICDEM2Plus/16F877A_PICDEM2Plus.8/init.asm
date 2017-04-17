; 
; File: init.asm
; Target: PIC16F877A
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
        __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF
;
; This RAM is used by the Interrupt Servoce Routine
; to save the context of the interrupted code.
INT_VAR     UDATA_SHR
w_temp      RES     1       ; variable used for context saving 
status_temp RES     1       ; variable used for context saving
pclath_temp RES     1       ; variable used for context saving

;**********************************************************************
RESET_VECTOR CODE 0x000                     ; processor reset vector
        nop                                 ; ICD2 needs this
        goto    start                       ; begin PIC initialization

INT_VECTOR code 0x004                       ; interrupt vector location

INTERRUPT:
        movwf   w_temp                      ; save off current W register contents
        movf    STATUS,w                    ; move status register into W register
        clrf    STATUS                      ; force to bank zero
        movwf   status_temp                 ; save off contents of STATUS register
        movf    PCLATH,W
        movwf   pclath_temp
        movlw   HIGH(INTERRUPT)
        movwf   PCLATH


; isr code can go here or be located as a called subroutine elsewhere


        movf    pclath_temp,W
        movwf   PCLATH
        movf    status_temp,w               ; retrieve copy of STATUS register
        movwf   STATUS                      ; restore pre-isr STATUS register contents
        swapf   w_temp,f
        swapf   w_temp,w                    ; restore pre-isr W register contents
        retfie                              ; return from interrupt

;------------------------------------------------------------------------
start:
    clrf    INTCON              ; Disable all interrupt sources
    banksel BANK1
    clrf    PIE1
    clrf    PIE2
    
    movlw   b'11000001'         ; Pull-ups off, INT edge low to high, WDT prescale 1:1 
    movwf   OPTION_REG          ; TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:4
                                ; TIMER0 will assert the overflow flag every 256*4 (1024)
                                ; instruction cycles, with a 4MHz oscilator this ia 1.024 milliseconds.
            
    movlw   b'11111111'         ; 
    movwf   TRISA           
            
    movlw   b'11111111'         ; 
    movwf   TRISB           
            
    movlw   b'11111111'         ; 
    movwf   TRISC           
    
    movlw   b'11111111'         ; 
    movwf   TRISD

    ; disable comparators
    movlw   b'00000111'
    movwf   CMCON
    
    ; Set all ADC inputs for digital I/O
    movlw   b'00000110'
    movwf   ADCON1
    
    banksel BANK0
    clrf    TMR0
    pagesel main
    goto    main

    END
