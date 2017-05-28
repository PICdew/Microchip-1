; -------------------------
; Button debounce functions
; -------------------------
;
#ifndef BUTTONS_INC
#define BUTTONS_INC
#ifdef  BUTTONS_ASM
#define ExtSymbol   global
#else
#define ExtSymbol   extern
#endif
;
; Declare the public symbols
;
    ExtSymbol   ButtonInit
    ExtSymbol   ButtonGetStatus
    ExtSymbol   ButtonPoll

; end of public symbols
#undefine ExtSymbol

;
;
;
#define ButtonS2 PORTA,4
#define ButtonS3 PORTA,5
#define BUTTON_DEBOUNCE_TIME    D'20'
#define BUTTON_S2_CHANGE_MASK   0x10
#define BUTTON_S3_CHANGE_MASK   0x20
#define BUTTON_S2_STATE_MASK    0x01
#define BUTTON_S3_STATE_MASK    0x02

#endif