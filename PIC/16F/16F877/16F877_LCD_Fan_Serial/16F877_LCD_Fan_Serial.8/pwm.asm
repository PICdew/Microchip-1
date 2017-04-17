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
; Function: Pwm_Init
; Input:    none
; Output:   none
; Returns:  none
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
; Function: Pwm_SetDutyCycle
; Input:    Pwm_DutyCycle 
; Output:   none
; Returns:  none
;
; Move the Pwm_DutyCycle register to the PWM registers.
; This is an insane amount of code to do this but it
; is required because of the way the 10-bits of duty
; cycle registers are mapped into the hardware.
;
Pwm_SetDutyCycle:
    banksel Pwm_DutyCycle
    swapf   Pwm_DutyCycle+0,W   ; Put 2-low duty cycle bits in proper position
    rrf     Pwm_DutyCycle+1,F   ; Shift 10-bits of duty cycle right two bits
    rrf     Pwm_DutyCycle+0,F   ; so it is the correct position for CCPR1L.
    rrf     Pwm_DutyCycle+1,F   ; Remember to not use instrions that alter the
    rrf     Pwm_DutyCycle+0,F   ; CARRY bit until we restore the Pwm_DutyCycle register.
    banksel CCP1CON
    xorwf   CCP1CON,W
    andlw   B'00110000'
    xorwf   CCP1CON,F           ; Update low 2-bits of PWM duty cycle
    banksel Pwm_DutyCycle
    movf    Pwm_DutyCycle,W
    banksel CCP1CON
    movwf   CCPR1L              ; Update high 8-bits of PWM duty cycle
    banksel Pwm_DutyCycle
    rlf     Pwm_DutyCycle+0,F   ; Restore the Pwm_DutyCycle register.
    rlf     Pwm_DutyCycle+1,F
    rlf     Pwm_DutyCycle+0,F
    rlf     Pwm_DutyCycle+1,F
    return
;
;
;
Pwm_DutyCycleUp:
    banksel Pwm_DutyCycle
    movf    Pwm_DutyCycle+0,W
    sublw   LOW (PWM_MAX_DUTY_CYCLE)
    movf    Pwm_DutyCycle+1,W
    skpc
    incfsz  Pwm_DutyCycle+1,W
    sublw   HIGH(PWM_MAX_DUTY_CYCLE)
    skpc
    return
    movlw   1
    addwf   Pwm_DutyCycle+0,F
    skpnc
    addwf   Pwm_DutyCycle+1,F
    goto    Pwm_SetDutyCycle
;
;
;
Pwm_DutyCycleDown:
    banksel Pwm_DutyCycle
    movf    Pwm_DutyCycle+0,W
    iorwf   Pwm_DutyCycle+1,W
    skpnz
    return
    movlw   0xFF
    addwf   Pwm_DutyCycle+0,F
    skpc
    addwf   Pwm_DutyCycle+1,F
    goto    Pwm_SetDutyCycle

    end
