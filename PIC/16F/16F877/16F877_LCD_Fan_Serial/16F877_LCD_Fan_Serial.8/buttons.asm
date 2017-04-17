; -------------------------
; Button debounce functions
; -------------------------
;
#define BUTTONS_ASM
#include "main.inc"
#include "buttons.inc"

BUTTON_DATA udata
ButtonStatus        res 1
ButtonSample        res 1
ButtonStable        res 1
ButtonChange        res 1
ButtonStableCount   res 1

BUTTON_CODE code
;
; ButtonGetStatus
; Returns Button status byte in the WREG
;
Button_GetStatus:
    banksel ButtonStatus
    movf    ButtonStatus,W
    andlw   BUTTON_S2_CHANGE_MASK | BUTTON_S3_CHANGE_MASK
    xorwf   ButtonStatus,F
    iorwf   ButtonStatus,W
    return
;
; ButtonPoll
; Poll the button inputs.
; To be called once per millisecond
;
Button_Poll:
    banksel ButtonStatus
    clrw
    btfss   ButtonS2    ; Skip if S2 not pressed
    iorlw   BUTTON_S2_STATE_MASK
    btfss   ButtonS3    ; Skip if S3 not pressed
    iorlw   BUTTON_S3_STATE_MASK
;
; WREG<1:0> = button sample, 1=pressed, 0=released
;
    xorwf   ButtonSample,W      ; W = current sample XOR with last sample
    xorwf   ButtonSample,F      ; Update last sample to current
    iorlw   0                   ; ZERO is set when no button changed between samples
    skpz                        ; Skip if no change between samples
    clrf    ButtonStableCount   ; Reset stable count
    incf    ButtonStableCount,W
    sublw   BUTTON_DEBOUNCE_TIME
    skpz                        ; skip when bouncing done
    incf    ButtonStableCount,F
    skpz                        ; skip when bouncing done
    return
    movf    ButtonSample,W
    xorwf   ButtonStable,W
    xorwf   ButtonStable,F
    movwf   ButtonChange
    swapf   ButtonChange,W
    iorwf   ButtonStable,W
    movwf   ButtonStatus
    return
;
; ButtonInit
; Setup PICDEM2 Plus button inputs
;
Button_Init:
    banksel BANK1
    bsf     ButtonS2    ; Make GPIO for switch S2 an input
    bsf     ButtonS3    ; Make GPIO for switch S3 an input
    banksel ButtonStatus
    clrf    ButtonStatus     
    clrf    ButtonSample    
    clrf    ButtonStable    
    clrf    ButtonChange    
    clrf    ButtonStableCount
    return

    end
