;   
; File: main.asm
; Target: PIC16F630, PIC16F676
; IDE: MPLABX v4.00
; Assembler: MPASM v5.75
;   
; Description:
;   See forum post: http://www.microchip.com/forums/FindPost/1027500
;
; Notes:
;   Build with MPASMWIN using absolute mode
;   
#ifdef __16F676
#include "p16F676.inc"
#define HAS_ADC
#endif
#ifdef __16F630
#include "p16F630.inc"
#endif
    
    list    r=dec
    errorlevel -302
    
    __CONFIG _FOSC_INTRCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF 

#define DELAY_COUNT 14
     
    cblock 0x20
        ShadowPortC  : 1
        DelayCounter : 1
    endc
   
        org 0x000
        banksel INTCON          ; Bank 0
        clrf    INTCON          ; Disable interrupts
;
; Now we try to set the internal Oscillator Calibration
; If the call to fetch the OSCCAL value fails then we will go through
; reset but the NOT_POR bit will be one. When this happens we do not set
; the OSCCAL register. This will result in running with the oscillator
; in uncalibrated mode insead of looping through reset forever.
;
        banksel PCON
        btfsc   PCON,NOT_POR    ; skip if this is a POR
        goto    no_POR
        bsf     PCON,NOT_POR    ; clear status of Power On Reset
        call    0x3FF           ; retrieve factory calibration value
        movwf   OSCCAL          ; update register with factory cal value 
no_POR:
        bsf     PCON,NOT_BOD    ; clear status of Brown Out Detect
;
; Put all of the GPIO pins in Digital mode
;
        banksel CMCON           ;
        movlw   0x07            ; Turn off comparators
        movwf   CMCON           ;
#ifdef HAS_ADC
        banksel ANSEL           ;
        clrf    ANSEL           ; Turn off analog inputs
#endif                          
        banksel OPTION_REG      ;
        movlw   0xDF            ; Set OPTION register
        movwf   OPTION_REG      ; TIMER0 clocks source is FCYC
;
; Set PORTC to outputs
;
        banksel TRISC
        movlw   0x00
        movwf   TRISC

        banksel ShadowPortC
        clrf    ShadowPortC
        movf    ShadowPortC,W
        movwf   PORTC

        movlw   DELAY_COUNT
        movwf   DelayCounter
;
; This is the main process loop
;
ProcessLoop:
        decfsz  DelayCounter,F
        goto    ProcessLoop
        nop
        nop
        incf    ShadowPortC,F
        movf    ShadowPortC,W
        movwf   PORTC
        movlw   DELAY_COUNT
        movwf   DelayCounter
        goto    ProcessLoop
        
        end
