; -------------------------
; LED functions
; -------------------------
;
#ifndef LEDS_INC
#define LEDS_INC
#ifdef  LEDS_ASM
#define ExtSymbol   global
#else
#define ExtSymbol   extern
#endif
;
; Declare the public symbols
;
    ExtSymbol   LedInit
    ExtSymbol   LedGet
    ExtSymbol   LedSet

; end of public symbols
#undefine ExtSymbol

;
; 
;
#define LED_PORT PORTB
#define LED_D2_MASK 0x01
#define LED_D3_MASK 0x02
#define LED_D4_MASK 0x04
#define LED_D5_MASK 0x08

#endif
