; ---------------------------
; RPM Routines
; ---------------------------
;
#define RPM_ASM
#include "main.inc"
#include "math.inc"
#include "rpm.inc"

RPM_VAR    UDATA
Rpm_PulseCount   res 2
Rpm_CountTimeout res 2

RPM_CODE   CODE
;
;
;
Rpm_Init:
    bcf     INTCON,INTE         ; disable external interrupts
    banksel OPTION_REG
    bsf     OPTION_REG,INTEDG   ; Select LOW to HIGH edge for INT assert

    banksel Rpm_PulseCount
    clrf    Rpm_PulseCount      ; Clear RPM counter
    clrf    Rpm_PulseCount+1
    return
;
;
;
Rpm_Start:
    bcf     INTCON,INTE         ; disable external interrupts

    banksel Rpm_PulseCount
    clrf    Rpm_PulseCount      ; Clear RPM counter
    clrf    Rpm_PulseCount+1

    movlw   LOW(RPM_COUNT_PERIOD)
    movwf   Rpm_CountTimeout
    movlw   HIGH(RPM_COUNT_PERIOD)
    movwf   Rpm_CountTimeout+1

    bcf     INTCON,INTF
    bsf     INTCON,INTE         ; enable external interrupts

    return
;
; Function: Rpm_status
; 
; Returns ZERO if the RPM capture period is complete
;
Rpm_Status:
    clrw
    btfsc   INTCON,INTE
    iorlw   1   
    return
    end
