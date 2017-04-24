; ---------------------------
; RPM Routines
; ---------------------------
;
#define RPM_ASM
#include "main.inc"
#include "math.inc"
#include "rpm.inc"

RPM_DATA    UDATA
Isr_FanPulseCount       res 2
Rpm_CountTimeout        res 2
Rpm_FanPulseCount       res 2
Fan_PulseNoiseFilter    res 1

RPM_CODE   CODE
;
;**********************************************************************
; Function: Rpm_Init
; Description:
;   Setup the external INTerrupt to be used to
;   count fan speed pulses.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
Rpm_Init:
    bcf     INTCON,INTE         ; disable external interrupts
    banksel OPTION_REG
    bsf     OPTION_REG,INTEDG   ; Select LOW to HIGH edge for INT assert

    banksel Rpm_FanPulseCount
    clrf    Rpm_FanPulseCount   ; Clear RPM counter
    clrf    Rpm_FanPulseCount+1
    return
;
;**********************************************************************
; Function: Rpm_Start
; Description:
;   Start a fan speed pulse count period.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
Rpm_Start:
    bcf     INTCON,INTE         ; disable external interrupts

    banksel Isr_FanPulseCount
    clrf    Isr_FanPulseCount   ; Clear RPM counter
    clrf    Isr_FanPulseCount+1

    movlw   LOW(RPM_COUNT_PERIOD)
    movwf   Rpm_CountTimeout
    movlw   HIGH(RPM_COUNT_PERIOD)
    movwf   Rpm_CountTimeout+1

    bcf     INTCON,INTF
    bsf     INTCON,INTE         ; enable external interrupts

    return
;
;**********************************************************************
; Function: Rpm_Status
; Description:
;   Check on the state of the RPM pulse count period.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  ZERO wheb the RPM capture period is complete
;
Rpm_Status:
    movf    Rpm_CountTimeout+0,W
    iorwf   Rpm_CountTimeout+1,W
    return

    end
