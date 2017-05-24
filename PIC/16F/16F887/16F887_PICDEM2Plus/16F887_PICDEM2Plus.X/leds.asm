; -------------------------
; LED functions
; -------------------------
;
#define LEDS_ASM
#include "main.inc"
#include "leds.inc"

LED_DATA udata
LedState    res 1

LED_CODE code
;
; LedGet
; Returns LEDs state in the WREG
;
LedGet:
    banksel LedState
    movf    LedState,W
    return
;
; LedSet
; Set LEDs state from bits in the WREG
;
LedSet:
    banksel LedState
    movwf   LedState
    movlw   ~(LED_D2_MASK | LED_D3_MASK | LED_D4_MASK | LED_D5_MASK)
    andwf   LED_PORT,F
    movf    LedState,W
    andlw   LED_D2_MASK | LED_D3_MASK | LED_D4_MASK | LED_D5_MASK
    iorwf   LED_PORT,F
    return
;
; LedInit
; Set LEDs GPIO pins to output and the LEDs to off
;
LedInit:
    banksel BANK1
    movlw   ~(LED_D2_MASK | LED_D3_MASK | LED_D4_MASK | LED_D5_MASK)
    andwf   LED_PORT,F
    banksel BANK0
    andwf   LED_PORT,F
    banksel LedState
    clrf    LedState
    return

    end
