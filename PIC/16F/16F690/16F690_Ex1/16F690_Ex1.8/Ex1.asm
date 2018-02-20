; MPLAB Exercise 1 - Rotate (Move the LED) 
#include <p16f690.inc>      ; #include - Brings in an include file defining all the Special Function Registers available on the PIC16F690. 
                            ; Also, it defines valid memory areas. These definitions match the names used in the device data sheet.
  
 __config (_INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _BOD_OFF & _IESO_OFF & _FCMEN_OFF) ; Config Defines the Configuration Word.
  
        org     0           ; Org 0 Tells the assembler where to start generating code. 
Display equ     20h         ; declare label addresses 
Delay1  equ     21h 
Delay2  equ     22h 
  
Start:
        BSF     STATUS,RP0  ; select Register Page 1 (RP) 
        CLRF    TRISC       ; make I/O PORTC all output 
        BCF     STATUS,RP0  ; back to Register Page 0 
        MOVLW   0x08        ; put '00001000' ie 8 in the working register 
        MOVWF   Display     ; moves the contents of Wreg to register – Display 
  
MainLoop: 
        MOVF    Display,W   ; Copy the display to the Wreg 
        MOVWF   PORTC       ; Copy the Wreg to Port C (to the LEDs) 

; Delay 0.2 Sec subroutine used for hardware test only (simply remove the ';' below and rebuild) 
; OndelayLoop: 
;       DECFSZ  Delay1,F    ; Decrement file register, skip next instruction if zero 
;       GOTO    OndelayLoop ; Repeat loop if Delay1 is not zero 
;       DECFSZ  Delay2,F    ; Decrement file register, skip next instruction if zero 
;       GOTO    OndelayLoop ; Repeat loop if Delay2 is not zero 
  
        BCF     STATUS,C    ; ensure the carry bit is clear 
        RRF     Display,F   ; Rotate Display right 
        BTFSC   STATUS,C    ; Did the bit rotate into the carry? 
        BSF     Display,3   ; If the bit went into the carry, put 8 back in 
        GOTO    MainLoop 
        END