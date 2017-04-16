; ---------------------------
; Interrupts Service Routines
; ---------------------------
;
#define ISR_ASM
#include "main.inc"
#include "isr.inc"
#include "tick.inc"
#include "buttons.inc"
;
; This RAM is used by the Interrupt Servoce Routine
; to save the context of the interrupted code.
; Note: 
;   The PIC16F873/PIC16F874/PIC16F873A/PIC16F874A do not have shared memory.
;   To save the context requires another method of declaring this section:
;
;   ISR_VAR_BANK0 UDATA 0x20
;   w_temp      RES     1   ; variable used for context saving 
;   
;   ISR_VAR_BANK1 UDATA 0xA0
;   w_temp_1    RES     1   ; Reserve offset in bank 1 for W when an interrupt asserts when this bank is selected
;
ISR_VAR_SHR UDATA_SHR   
w_temp      RES     1   ; variable used for context saving 

ISR_VAR     UDATA
status_temp RES     1   ; variable used for context saving
pclath_temp RES     1   ; variable used for context saving

ISR_VECTOR code 0x004                       ; interrupt vector location

INTERRUPT:
    movwf   w_temp                          ; save off current W register contents
    movf    STATUS,w                        ; move status register into W register
    banksel status_temp
    movwf   status_temp                     ; save off contents of STATUS register
    movf    PCLATH,W                        
    movwf   pclath_temp                     
    movlw   HIGH(INTERRUPT)                 ; Set program page to the curent page so 
    movwf   PCLATH                          ; that GOTO and CALL branch to this page


; isr code can go here or be located as a called subroutine elsewhere

;
; Handle TIMER0 interrupts
;
ISR_TMR0:
    btfss   INTCON,TMR0IE                   ; Skip if TIMER0 interrupt is emabled
    goto    ISR_TMR0_Done
    btfss   INTCON,TMR0IF
    goto    ISR_TMR0_Done
;
    bcf     INTCON,TMR0IF                   ; Clear TIMER0 interrupt request
;
; Advance the button debouce state every system tick
;
    lcall   Button_Poll
    pagesel ISR_TMR0
    banksel SystemTickTimeout
;
; Decrement the system tick timeout
;
    movf    SystemTickTimeout+1,W           ; Test the SystemTickTimeout for zero and
    iorwf   SystemTickTimeout,W             ; decrement it by one when it is not zero.
    skpz                                    ;
    movlw   0xFF                            ; The SystemTickTimeout is intended to be polled during the process loop
    addwf   SystemTickTimeout,F             ; process loop to determine when the interval has expired.
    skpc                                    ; When the process loop writes to the SystemTickTimeout the TIMER0
    addwf   SystemTickTimeout+1,F           ; interrupt must be disabled.
ISR_TMR0_Done:
;

    banksel status_temp
    movf    pclath_temp,W                   
    movwf   PCLATH                          
    movf    status_temp,w                   ; retrieve copy of STATUS register
    movwf   STATUS                          ; restore pre-isr STATUS register contents
    swapf   w_temp,f                        
    swapf   w_temp,w                        ; restore pre-isr W register contents
    retfie                                  ; return from interrupt

    end
