; ---------------------------
; Interrupts Service Routines
; ---------------------------
;
#define ISR_ASM
#include "main.inc"
#include "isr.inc"
#include "tick.inc"
#include "rpm.inc"
#include "buttons.inc"
;
; This RAM is used by the Interrupt Servoce Routine
; to save the context of the interrupted code.
; Note: 
;   The PIC16F873/PIC16F874/PIC16F873A/PIC16F874A do not have shared memory.
;   To save the context requires another method of declaring this section:
;
;   ISR_VAR_BANK0 UDATA 0x20
;   w_temp      RES     1   ; variable used for context saving 
;   
;   ISR_VAR_BANK1 UDATA 0xA0
;   w_temp_1    RES     1   ; Reserve offset in bank 1 for W when an interrupt asserts when this bank is selected
;
ISR_VAR_SHR UDATA_SHR   
w_temp      RES     1   ; variable used for context saving 

ISR_VAR     UDATA
status_temp RES     1   ; variable used for context saving
pclath_temp RES     1   ; variable used for context saving
fsr_temp    RES     1   ; variable used for context saving

ISR_VECTOR code 0x004                       ; interrupt vector location

INTERRUPT:
    movwf   w_temp              ; save off current W register contents
    movf    STATUS,w            ; move status register into W register
    banksel BANK0
    movwf   status_temp         ; save off contents of STATUS register
    movf    PCLATH,W
    movwf   pclath_temp         ; Save PCLATCH register
    movf    FSR,W
    movwf   fsr_temp            ; Save File Select Register
    movlw   HIGH(INTERRUPT)     ; Set program page to the current page so
    movwf   PCLATH              ; that GOTO and CALL branch to this page
;
; Handle INT interrupts
;
ISR_INT:
    btfss   INTCON,INTE                     ; Skip if external interrupt is enabled
    goto    ISR_INT_Done
    btfss   INTCON,INTF                     ; Skip if external interrupt is asserted
    goto    ISR_INT_Done
;
    bcf     INTCON,INTE                     ; Clear external interrupt enable
;
    banksel BANK1                           ; Count both edges
    movlw   (1<<INTEDG)
    xorwf   OPTION_REG,F
    banksel BANK0
;
; The external interrupt is used to count
; pulses from the fan speed output.
;
    banksel Fan_PulseNoiseFilter
    movf    Fan_PulseNoiseFilter,W
    movlw   1               
    skpz                                    ; skip if enough time since last pulse counted
    movlw   0               
    addwf   Isr_FanPulseCount,F                ; Increment fan speed pulse count
    skpnc
    addwf   Isr_FanPulseCount+1,F
    movlw   FAN_PULSE_FILTER_SYSTEM_TICKS   ; Start timeout between pulse counts to help
    addwf   Fan_PulseNoiseFilter,F          ; reject noise on fan speed pulse output.
ISR_INT_Done:
;
; Handle TIMER0 interrupts
;
ISR_TMR0:
    btfss   INTCON,TMR0IE                   ; Skip if TIMER0 interrupt is enabled
    goto    ISR_TMR0_Done
    btfss   INTCON,TMR0IF                   ; Skip if TIMER0 interrupt is asserted
    goto    ISR_TMR0_Done
;
    bcf     INTCON,TMR0IF                   ; Clear TIMER0 interrupt request

    lcall   Button_Poll
    pagesel ISR_TMR0

    banksel Fan_PulseNoiseFilter
    bsf     STATUS,C
    movf    Fan_PulseNoiseFilter,W          ; Check if enough ticks since the last
    skpz                                    ; fans speed pulse has been counted.
    decfsz  Fan_PulseNoiseFilter,W          ; Decrement noise timeout counter when non-zero
    bcf     STATUS,C
    movwf   Fan_PulseNoiseFilter
    btfss   STATUS,C
    goto    ISR_TMR0_FilterDone
    bcf     INTCON,INTF                     ; Clear the external interrupt assert when rejecting noise
    bsf     INTCON,INTE                     ; Enable fan speed pulse counting while sample period is going
ISR_TMR0_FilterDone:
;
; Decrement the RPM period timeout
;
    banksel Rpm_CountTimeout
    movf    Rpm_CountTimeout+0,W            ; Test the Rpm_CountTimeout for zero and
    iorwf   Rpm_CountTimeout+1,W
    skpz                                    ; decrement it by one when it is not zero.
    movlw   -1
    addwf   Rpm_CountTimeout+0,F
    skpc
    addwf   Rpm_CountTimeout+1,F
    skpc
    bcf     INTCON,INTE
ISR_TMR0_RpmDone:
;
ISR_TMR0_Done:
;
    banksel BANK0
    movf    fsr_temp,W
    movwf   FSR
    movf    pclath_temp,W
    movwf   PCLATH
    movf    status_temp,w       ; retrieve copy of STATUS register
    movwf   STATUS              ; restore pre-isr STATUS register contents
    swapf   w_temp,f
    swapf   w_temp,w            ; restore pre-isr W register contents
    retfie                      ; return from interrupt

    end
