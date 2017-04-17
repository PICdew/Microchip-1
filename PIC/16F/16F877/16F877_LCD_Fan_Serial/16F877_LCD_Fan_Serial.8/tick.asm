; ---------------------------
; Interrupts Service Routines
; ---------------------------
;
#define TICK_ASM
#include "main.inc"
#include "tick.inc"

TICK_VAR    UDATA
SystemTickTimeout   res     2

TICK_CODE   CODE

Tick_Init:
    bcf     INTCON,TMR0IE       ; Disable TIMER0 interrupts

    banksel SystemTickTimeout   ; Clear system tick timeout
    clrf    SystemTickTimeout
    clrf    SystemTickTimeout+1

    banksel BANK1
    bcf     OPTION_REG,T0CS     ; Set TIMER0 clock source to FCYC (oscillator frequency / 4)
    bcf     OPTION_REG,PSA      ; Assign prescaler to TIMER0
    bcf     OPTION_REG,PS2      ; Set TIMER0 prescale to 1:8
    bsf     OPTION_REG,PS1      ; TIMER0 will assert the overflow flag every 256*8 (2048)
    bcf     OPTION_REG,PS0      ; instruction cycles, with a 8MHz oscilator this ia 1.024 milliseconds.

    banksel TMR0
    clrf    TMR0
    bcf     INTCON,TMR0IF
    bsf     INTCON,TMR0IE       ; Enable TIMER0 interrupts

    return

    end
