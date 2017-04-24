; ---------------------------
; PWM Routines
; ---------------------------
;
#ifndef PWM_INC
#define PWM_INC
#ifdef  PWM_ASM
#define ExtSymbol   global
#else
#define ExtSymbol   extern
#endif
;
; Declare the public symbols
;
    ExtSymbol   Pwm_Init
    ExtSymbol   Pwm_SetDutyCycle
    ExtSymbol   Pwm_DutyCycleUp
    ExtSymbol   Pwm_DutyCycleDown
    ExtSymbol   Pwm_DutyCycle

; end of public symbols
#undefine ExtSymbol
;
; 
;
#define PWM_FREQUENCY (D'25000')
#define PWM_PERIOD (FCYC/PWM_FREQUENCY)
#define PWM_MAX_DUTY_CYCLE (PWM_PERIOD*4)
#define PWM_MIN_DUTY_CYCLE (0)

#endif