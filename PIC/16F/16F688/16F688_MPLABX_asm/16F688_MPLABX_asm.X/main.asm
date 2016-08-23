;   
; File: main.asm
; Target: PIC16F688
; IDE: MPLAB v3.35
; Assembler: MPASMWIN v5.68
;   
; Additional files:
;   P16F688.INC
;   16f688_g.lkr
;   
; Description:
;   Minimal assembly language template to setup the PIC16F688 for a generic application loop
;
;   
#include "p16F688.inc"
    
    list    r=dec
    errorlevel -302
    
     __CONFIG _FOSC_INTOSCIO & _WDTE_ON & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF
     
#define FOSC (8000000)
#define FCYC (FOSC/4)
;
; Reset vector
;
RESET_VECTOR CODE  0x000
        pagesel start
        goto    start
    
ISR_DATA    UDATA
WREG_SAVE   res     1
STATUS_SAVE res     1
PCLATH_SAVE res     1
;
; Interrupt vector
;    
ISR_VECTOR  CODE    0x004
        movwf   WREG_SAVE       ; Save the current 
        movf    STATUS,W        ; execution context. 
        movwf   STATUS_SAVE     ; 
        movf    PCLATH,W        ; 
        movwf   PCLATH_SAVE     ; 
        clrf    STATUS          ; Set the ISR handler context to RAM 
        clrf    PCLATH          ; at bank zero and CODE in page zero.
;
; Put interrupt handlers here
;

;
; All handlers must exit through here
;    
ISR_Exit:
        movf    PCLATH_SAVE,W
        movwf   PCLATH
        movf    STATUS_SAVE,W
        movwf   STATUS
        swapf   WREG_SAVE,F
        swapf   WREG_SAVE,W
        retfie
;   
; Startup code to initialize the PIC for a 
; particular application. This one is generic
; with most of he GPIO pins set as outputs.
;    
start:
        banksel OSCCON
        movlw   0x70
        movwf   OSCCON      ; Set internal oscillator to 8MHz
    
        banksel INTCON      ; Bank 0
        clrf    INTCON      ; Disable interrupts
;   
; Set all outputs to zero
;   
        movlw   0x00
        movwf   PORTA
        movwf   PORTC
    
        banksel ANSEL       ; Bank 2
        clrf    ANSEL
    
        banksel OPTION_REG  ; Bank1
        movlw   0xDF        ; Set OPTION register
        movwf   OPTION_REG  ; TIMER0 clocks source is FCYC
    
        clrf    PIE1        ; Clear all peripheral interrupt enables.
    
;   
; Set GPIO direction
;   
        movlw   0x30
        movwf   TRISA       ; RA5-RA4 inputs, RA3-RA0 outputs
        movlw   0x00
        movwf   TRISC       ; RC5-RC0 outputs
        banksel PORTA       ; Bank 0
        pagesel main
        goto    main
;
; Main code
;
MAIN_CODE CODE
main:
;   
; Application loop
;   
AppLoop:
    
        goto    AppLoop
    
        end
