;
;  Date: 2017-June-8
;  File: main.asm
;  Target: PIC16F628A
;  OS: Win7 64-bit
;  MPLABX: v3.61
;  Compiler: MPASMWIN v5.73
;
;  Description:
;   Quadrature debouncer. State of the Qxx_in pins are sampled,
;   debounced then presented to the Qxx_out pins.
;
;   The Q_out_stable output is asserted low for 5 millisecond
;   each time a new state is placed on the Qxx_out pins.
;
;                       PIC16F628A
;                +----------:_:----------+
;           <> 1 : RA2               RA1 : 18 <>
;           <> 2 : RA3               RA0 : 17 <> Q_out_stable
;           <> 3 : RA4          OSC1/RA7 : 16 <>
;       VPP -> 4 : RA5/VPP      OSC2/RA6 : 15 <>
;       GND -> 5 : VSS               VDD : 14 <- PWR
;   Q2B_out <> 6 : RB0/INT       PGD/RB7 : 13 <> Q1A_in
;   Q2A_out <> 7 : RB1/RX/DT     PGC/RB6 : 12 <> Q1B_in
;   Q1B_out <> 8 : RB2/RX/CK         RB5 : 11 <> Q2A_in
;   Q1A_out <> 9 : RB3/CCP       PGM/RB4 : 10 <> Q2B_in
;                +-----------------------:
;                         DIP-18
;
;
;  MPLAB required files:
;   P16F628A.INC
;   16F628A_G.LKR
;
    list      p=16F628A     ; list directive to define processor
    list      r=dec         ; list directive to set the default radix
    list      n=0,c=250     ; list directive to set no page breaks, long lines
    #include <p16F628A.inc> ; processor specific variable definitions
    errorlevel -224         ; suppress deprecated instruction warnings for TRIS opcode
    errorlevel -312         ; suppress page or bank warning when building for parts with only one page
;
    __CONFIG   _CP_OFF & _CPD_OFF & _LVP_OFF & _BODEN_OFF & _MCLRE_ON & _WDT_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT
;
; Define macros to help with
; bank selection
;
#define BANK0  (h'000')
#define BANK1  (h'080')
#define BANK2  (h'100')
#define BANK3  (h'180')
;
;
; This RAM is used by the Interrupt Service Routine
; to save the context of the interrupted code.
INT_VAR     UDATA_SHR
w_temp      RES     1       ; variable used for context saving
status_temp RES     1       ; variable used for context saving
pclath_temp RES     1       ; variable used for context saving
;
;**********************************************************************
RESET_VECTOR CODE 0x000     ; processor reset vector
    nop                     ; ICD2 needs this
    pagesel start
    goto    start           ; go to beginning of program
;
INT_VECTOR code 0x004       ; interrupt vector location
;
INTERRUPT:
    movwf   w_temp          ; save off current W register contents
    movf    STATUS,w        ; move status register into W register
    clrf    STATUS          ; force to bank zero
    movwf   status_temp     ; save off contents of STATUS register
    movf    PCLATH,W
    movwf   pclath_temp
    movlw   HIGH(INTERRUPT)
    movwf   PCLATH
;
; ISR code can go here or be located as a called subroutine elsewhere
;
    movf    pclath_temp,W
    movwf   PCLATH
    movf    status_temp,w   ; retrieve copy of STATUS register
    movwf   STATUS          ; restore pre-ISR STATUS register contents
    swapf   w_temp,f
    swapf   w_temp,w        ; restore pre-ISR W register contents
    retfie                  ; return from interrupt
;
START_CODE  code
;------------------------------------------------------------------------
start:
;
; Turn off all analog inputs
; and make all pins available
; for digital I/O.
;
    clrf    INTCON          ; Turn off all interrupt sources
    banksel BANK1
    clrf    (PIE1   ^ BANK1)
;
    movlw   b'00000000'     ; Turn off Comparator voltage reference
    movwf   (VRCON  ^ BANK1)
;
    movlw   b'01010001'     ; Setup OPTION register
                            ; PORTB pull-ups enabled
                            ; TIMER0 clock source is instruction clock
                            ; TIMER0 prescaler is 1:4
    movwf   (OPTION_REG ^ BANK1)
;
    banksel BANK0
;
    movlw   0x07            ; turn off Comparators
    movwf   (CMCON  ^ BANK0)
;
    pagesel main
    goto    main
;
;
;------------------------------------------------------------------------
;
#define Q_DEBOUNCE_TICKS (20)
#define PULSE_TICKS (5)
;
MAIN_DATA udata 0x20        ; locate in bank0
Q_InSample          res 1
Q_DebounceTimer     res 1
PulseTimer          res 1
;
MAIN_CODE code
;
;
;
main:
    movlw   0xFF
    banksel BANK1
    movwf   (TRISB ^ BANK1)
    bcf     (TRISA ^ BANK1),0
    banksel BANK0
    movf    PORTB,W
    andlw   0xF0
    movwf   Q_InSample
    clrf    Q_DebounceTimer
    clrf    TMR0
    bcf     INTCON,T0IF
    bsf     PORTA,0         ; Release data update available
    clrf    PulseTimer
;
AppLoop:
    movf    PORTB,W
    xorwf   Q_InSample,W
    andlw   0xF0
    btfss   STATUS,Z        ; skip if inputs unchanged
    goto    Q_InputsChanging
    movf    Q_DebounceTimer,F
    btfsc   STATUS,Z        ; skip if input not stable long enough
    goto    Q_InputsStable
CheckTimerAndLoop:
    btfss   INTCON,T0IF     ; skip if 1.024 milliseconds have gone by
    goto    AppLoop
    bcf     INTCON,T0IF
    movf    PulseTimer,F
    btfss   STATUS,Z        ; skip if Tick count has timed out
    decfsz  PulseTimer,F    ; skip when pulse timer counts from one to zero
    goto    PulseHasTimedOut
    btfsc   PORTA,0         ; skip when pulse output is asserted
    goto    PulseHasTimedOut
    bsf     PORTA,0         ; Release data update available at 5 milliseconds
    movlw   0xFF
    tris    PORTB           ; make all PORTB input pins
    movlw   PULSE_TICKS     ; Start pulse timeout for "not asserted" time
    movwf   PulseTimer
PulseHasTimedOut:
    movf    Q_DebounceTimer,F
    btfss   STATUS,Z        ; skip if inputs stable
    decf    Q_DebounceTimer,F
    goto    AppLoop
;
Q_InputsChanging:
    xorwf   Q_InSample,F    ; update input sample
    movlw   Q_DEBOUNCE_TICKS
    movwf   Q_DebounceTimer
    goto    CheckTimerAndLoop
;
Q_InputsStable:
    movf    PulseTimer,F
    btfss   STATUS,Z        ; Skip when pulse timer is finished
    goto    CheckTimerAndLoop
    swapf   Q_InSample,W
    xorwf   Q_InSample,W
    andlw   0x0F
    btfsc   STATUS,Z        ; Skip if output bit need to change
    goto    CheckTimerAndLoop
    xorwf   Q_InSample,F    ; Update output bits on change
    movf    Q_InSample,W
    xorlw   0x0F            ; Reverse direction of rotary switch
    movwf   PORTB           ; Put new data on output bits
    movlw   0xF0
    tris    PORTB           ; Make pins 0-3 outputs
    movlw   PULSE_TICKS     ; Start pulse timeout for "asserted" time
    movwf   PulseTimer
    bcf     PORTA,0         ; Assert data update available
    goto    CheckTimerAndLoop
;
    END
