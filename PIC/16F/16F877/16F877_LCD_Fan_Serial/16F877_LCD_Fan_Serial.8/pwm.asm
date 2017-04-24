; ---------------------------
; PWM Routines
; ---------------------------
;
#define PWM_ASM
#include "main.inc"
#include "pwm.inc"

PWM_VAR    UDATA
Pwm_DutyCycle   res 2

PWM_CODE   CODE
;
;**********************************************************************
; Function: Pwm_Init
; Description:
;   Setup TIMER2 for PWM period and initialize
;   the CCP1 to produce a PWM output on pin RC2.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
Pwm_Init:
    banksel PIE1                ; Disable TIMER2 and CCP1 interruprs
    bcf     PIE1,TMR2IE
    bcf     PIE1,CCP1IE
    bcf     TRISC,TRISC2        ; Make CCP1 an output
    banksel T2CON
    clrf    T2CON               ; Stop TIMER2
    clrf    CCP1CON             ; Stop PWM1
    movlw   PWM_PERIOD-1
    banksel PR2
    movwf   PR2                 ; Setup PWM period
    movlw   B'00001100'
    banksel CCP1CON
    movwf   CCP1CON             ; Enable PWM
    clrf    CCPR1L              ; Make first PWM duty cycle 0%
    clrf    CCPR1H
    bsf     T2CON,TMR2ON        ; turn on PWM
    movlw   1
    banksel PR2
    addwf   PR2,W               ; WREG+CARRY = 100% duty cycle
    banksel Pwm_DutyCycle
    clrf    Pwm_DutyCycle+1     ; Set initial duty cycle to 25%
    movwf   Pwm_DutyCycle+0
    skpnc
    bsf     Pwm_DutyCycle+1,1
    goto    Pwm_SetDutyCycle
;
;**********************************************************************
; Function: Pwm_SetDutyCycle
; Description:
;   Move the Pwm_DutyCycle register to the PWM registers.
;   This is an insane amount of code to do this but it
;   is required because of the way the 10-bits of duty
;   cycle registers are mapped into the hardware.
;
; Inputs:   Pwm_DutyCycle
;
; Outputs:  none
;
; Returns:  nothing
;
; Notes:    Uses the FSR as temporary storage for bit rotates
;
Pwm_SetDutyCycle:
    banksel Pwm_DutyCycle
    rrf     Pwm_DutyCycle+1,W   ; Shift 10-bits of duty cycle right two bits
    rrf     Pwm_DutyCycle+0,W   ; to get them in to the proper positions
    movwf   FSR                 ; for the CCPRxL registers.
    clrc                        ;
    rrf     FSR,F               ; It is just weird that Microchip put these
    btfsc   Pwm_DutyCycle+1,1   ; bits in such a clumsy order.
    bsf     FSR,7
    swapf   Pwm_DutyCycle+0,W   ; Put 2-low duty cycle bits in proper position
    banksel CCP1CON
    xorwf   CCP1CON,W           ; for the CCPxCON register.
    andlw   B'00110000'
    xorwf   CCP1CON,F           ; Update low 2-bits of PWM duty cycle
    movf    FSR,W
    movwf   CCPR1L              ; Update high 8-bits of PWM duty cycle
    return
;
;**********************************************************************
; Function: Pwm_DutyCycleUp
; Description:
;   Increments the PWM duty cycle up to 100%
;   and sets the hardware for the new duty cycle.
;
; Inputs:   Pwm_DutyCycle
;
; Outputs:  Pwm_DutyCycle
;
; Returns:  nothing
;
Pwm_DutyCycleUp:
    banksel Pwm_DutyCycle
    movf    Pwm_DutyCycle+0,W
    sublw   LOW (PWM_MAX_DUTY_CYCLE-1)
    movf    Pwm_DutyCycle+1,W
    skpc
    incfsz  Pwm_DutyCycle+1,W
    sublw   HIGH(PWM_MAX_DUTY_CYCLE-1)
    skpc
    return
    movlw   1
    addwf   Pwm_DutyCycle+0,F
    skpnc
    addwf   Pwm_DutyCycle+1,F
    goto    Pwm_SetDutyCycle
;
;**********************************************************************
; Function: Pwm_DutyCycleDown
; Description:
;   Decrements the PWM duty cycle down to 0%
;   and sets the hardware for the new duty cycle.
;
; Inputs:   Pwm_DutyCycle
;
; Outputs:  Pwm_DutyCycle
;
; Returns:  nothing
;
Pwm_DutyCycleDown:
    banksel Pwm_DutyCycle
    movf    Pwm_DutyCycle+0,W
    sublw   LOW (PWM_MIN_DUTY_CYCLE)
    movf    Pwm_DutyCycle+1,W
    skpc
    incfsz  Pwm_DutyCycle+1,W
    sublw   HIGH(PWM_MIN_DUTY_CYCLE)
    skpnc
    return
    movlw   0xFF
    addwf   Pwm_DutyCycle+0,F
    skpc
    addwf   Pwm_DutyCycle+1,F
    goto    Pwm_SetDutyCycle

    end
