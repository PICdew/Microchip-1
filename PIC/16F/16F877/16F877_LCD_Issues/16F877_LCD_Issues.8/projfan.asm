        list    n=0, c=250      ; No page breaks, support long lines in list file
        list    r=dec           ; Set default radix to decimal
        errorlevel -302         ; Suppress not in bank zero warning
;
; File: projfan.asm
; Target: PIC16F877
; IDE: MPLAB v8.92
; Compiler: MPASMWIN v5.51
;
;                         PIC16F877
;                 +----------:_:----------+
;   S1  VPP ->  1 : MCLR/VPP      PGD/RB7 : 40 <> PGD
; R16(0-5V) ->  2 : RA0/AN0       PGC/RB6 : 39 <> PGC
;           <>  3 : RA1               RB5 : 38 <>
;           <>  4 : RA2               RB4 : 37 <>
;           <>  5 : RA3           PGM/RB3 : 36 <>    LED_D5
;   S2      ->  6 : RA4               RB2 : 35 <>    LED_D4
;           <>  7 : RA5               RB1 : 34 <>    LED_D3
;           <>  8 : RE0               RB0 : 33 <> S3/LED_D2
;           <>  9 : RE1               VDD : 32 <- PWR
;           <> 10 : RE2               VSS : 31 <- GND
;       PWR -> 11 : VDD               RD7 : 30 -> LCD_ON
;       GND -> 12 : VSS               RD6 : 29 -> LCD_E
; 8MHz XTAL -> 13 : OSC1              RD5 : 28 -> LCD_RW
; 8MHz XTAL <- 14 : OSC2              RD4 : 27 -> LCD_RS
;           <> 15 : RC0/T1CKI   RX/DT/RC7 : 26 <- RXD
;           <> 16 : RC1/CCP2    TX/CK/RC6 : 25 -> TXD
;    BUZZER <> 17 : RC2/CCP1          RC5 : 24 <>
;       SCL <> 18 : RC3/SCL       SDA/RC4 : 23 <> SDA
;    LCD_D4 <> 19 : RD0               RD3 : 22 <> LCD_D7
;    LCD_D5 <> 20 : RD1               RD2 : 21 <> LCD_D6
;                 +-----------------------:
;                          DIP-40
;
; Description:
;   Fan speed control application.
;
;   We are going to use only DATA bank zero and CODE page zero for
;   this project to avoid using a lot of bank and page selects.
;
;   If we need more DATA or CODE space it will be a problem we
;   deal with in the future.
;
;**********************************************************************
; Select target processor and include
; processor specific symbols.
;
#ifdef __16F877
    list    p=16F877        ; Select PIC16F877  as target device
    #include <p16f877.inc>
#endif

#ifdef __16F877A
    list    p=16F877A       ; Select PIC16F877A  as target device
    #include <p16f877a.inc>
#endif
;
;**********************************************************************
; Configuration words.
;
    __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF
;
;**********************************************************************
; Define macros to help with bank selection
;
#define BANK0  (h'000')
#define BANK1  (h'080')
#define BANK2  (h'100')
#define BANK3  (h'180')
;
;**********************************************************************
; Define the system oscillator frequency and instruction cycle frequency
;
#define FSYS (d'8000000')
#define FCYC (FSYS/d'4')
;
;**********************************************************************
; UART constants
;
#define CR (D'13')
#define LF (D'10')
#define BAUD_RATE (D'9600')
;
;**********************************************************************
; LCD constants
;
; Define the LCD port pins
#define LCD_POWER_EN  PORTD,7
#define E_PIN         PORTD,6
#define RW_PIN        PORTD,5
#define RS_PIN        PORTD,4
#define LCD_DATA_BITS 0x0F
#define LCD_PORT      PORTD
#define LCD_FORMAT    (FOUR_BIT&LINES_5X7)
;#define USE_FAST_CLOCK

;
;
;/* Display ON/OFF Control defines */
#define DON         b'00001111'  ;/* Display on      */
#define DOFF        b'00001011'  ;/* Display off     */
#define CURSOR_ON   b'00001111'  ;/* Cursor on       */
#define CURSOR_OFF  b'00001101'  ;/* Cursor off      */
#define BLINK_ON    b'00001111'  ;/* Cursor Blink    */
#define BLINK_OFF   b'00001110'  ;/* Cursor No Blink */

;/* Cursor or Display Shift defines */
#define SHIFT_CUR_LEFT    b'00010011'  ;/* Cursor shifts to the left   */
#define SHIFT_CUR_RIGHT   b'00010111'  ;/* Cursor shifts to the right  */
#define SHIFT_DISP_LEFT   b'00011011'  ;/* Display shifts to the left  */
#define SHIFT_DISP_RIGHT  b'00011111'  ;/* Display shifts to the right */

;/* Function Set defines */
#define FOUR_BIT   b'00101111'  ;/* 4-bit Interface               */
#define EIGHT_BIT  b'00111111'  ;/* 8-bit Interface               */
#define LINE_5X7   b'00110011'  ;/* 5x7 characters, single line   */
#define LINE_5X10  b'00110111'  ;/* 5x10 characters               */
#define LINES_5X7  b'00111011'  ;/* 5x7 characters, multiple line */

; Start address of each line
#define LINE_ONE    0x00
#define LINE_TWO    0x40
#define LINE_THREE  0x14
#define LINE_FOUR   0x54
;
;**********************************************************************
; PWM constants
;
#define PWM_FREQUENCY (D'25000')
#define PWM_PERIOD (FCYC/PWM_FREQUENCY)
#define PWM_MAX_DUTY_CYCLE (PWM_PERIOD*4)
#define PWM_MIN_DUTY_CYCLE (0)
;
;**********************************************************************
; RPM constants
;
; The RPM count period is 250 system ticks.
; A system tick is 1.024 milliseconds, 250 
; ticks is 250 * 1.024 or 256 milliseconds.
;
; To convert Isr_FanPulseCount to RPMs we use this forumla:
;
; RPM = ((Isr_FanPulseCount / Pulses per revolution) / Pulse count period in milliseconds) * Milliseconds in one minute)
;
; For fan P/N:AFB0712VHB-F00 there are 2 pulses or 4 edges per revolution.
; RPM = ((Isr_FanPulseCount / 2) / 256) * 60000)
;     = ((Isr_FanPulseCount / 256) * 30000)
;     = ( Isr_FanPulseCount * 30000 / 256 )
;
; For fan P/N:THA0412BN there are 4 pulses or 8 edges per revolution.
; RPM = ((Isr_FanPulseCount / 4) / 256) * 60000)
;     = ((Isr_FanPulseCount / 256) * 15000)
;     = ((Isr_FanPulseCount * 15000) / 256 )
;
; When the fan spins at 20520 RPM it produces 342 revolutions in one second.
; At 4 edges per revolution this is at most 1368 counts in one second.
; This gives at most 351 counts in 256 milliseconds.
;
; The maximum product we expect is 15000 * 351, or 5265000. This fits in 24-bits.
; 
;
#define MILLISECONDS_IN_ONE_MINUTE (D'60000')
#define SYSTEM_TICKS_IN_256MS (D'250')
#define NUMBER_OF_SAMPLE_PERIODS (D'5')
#define EDGES_PER_REVOLUTION (D'4')
#define FAN_PULSE_FILTER_SYSTEM_TICKS (D'7')
#define RPM_COUNT_PERIOD (SYSTEM_TICKS_IN_256MS*NUMBER_OF_SAMPLE_PERIODS)
#define K1 (MILLISECONDS_IN_ONE_MINUTE/(NUMBER_OF_SAMPLE_PERIODS*EDGES_PER_REVOLUTION))
;
;**********************************************************************
; All memory is declared here
;
    cblock 0x20
        status_temp:1           ; used for ISR context saving
        pclath_temp:1           ; used for ISR context saving
        fsr_temp:1              ; used for ISR context saving
        Uart_pszRomStr:2        ; used by UART when printing ASCII strings from the CODE space
        LCD_pszRomStr:2         ; used by LCD when printing ASCII strings from the CODE space
        LCD_byte:1              ; used by LCD to save byte sent to or read from LCD
        LCD_BusyBit:1           ; used by LCD to store the mask of where the BUSY bit is located
        Pwm_DutyCycle:2         ; used by PWM to store the duty cycle
        Isr_FanPulseCount:2     ; used by RPM ISR to count pulses during sample period
        Rpm_FanPulseCount:2     ; used by RpmTest as snapshot of fan speed count
        Rpm_CountTimeout:2      ; used by RPM to set the pulse count sample period
        Fan_PulseNoiseFilter:1  ; used by RPM ISR to reject fan speed pulse noise
        A_reg:2                 ; used by Math functions, 16-bit input  register A
        B_reg:0                 ; used by Math functions, 16-bit input  register B, register shares the low 16-bits of the output register
        D_reg:4                 ; used by Math functions, 32-bit output register D
        mBits:1                 ; used by Math functions, used for bit counts
    endc
;
; Shared memory block
; Note:
;   For the PIC16F877 the shared memory block is a 16 byte
;   region from 0x070 to 0x07F that is the same memory
;   regardless of how the DATA bank bits are set.
;
;   The In-Circuit-Debug reserves location 0x070 for debug
;   support. Our application will not use this location.
;
    cblock 0x71
        w_temp:1                ; used for ISR context saving
    endc
;
;**********************************************************************
; Reset vector
;
RESET:
    org     0x000               ; processor reset vector
    nop                         ; ICD2 needs this
    goto    start               ; begin PIC initialization
;
;**********************************************************************
; Interrupt vector
;
    org     0x004               ; interrupt vector location
INTERRUPT:
    movwf   w_temp              ; save off current W register contents
    movf    STATUS,w            ; move status register into W register
    banksel BANK0
    movwf   status_temp         ; save off contents of STATUS register
    movf    PCLATH,W
    movwf   pclath_temp         ; Save PCLATCH register
    movf    FSR,W
    movwf   fsr_temp            ; Save File Select Register
    movlw   HIGH(INTERRUPT)     ; Set program page to the current page so
    movwf   PCLATH              ; that GOTO and CALL branch to this page
;
; Handle INT interrupts
;
ISR_INT:
    btfss   INTCON,INTE                     ; Skip if external interrupt is enabled
    goto    ISR_INT_Done
    btfss   INTCON,INTF                     ; Skip if external interrupt is asserted
    goto    ISR_INT_Done
;
    bcf     INTCON,INTE                     ; Clear external interrupt enable
    bsf     PORTE,0                         ; toggle RE0 (DEBUG)
;
    banksel BANK1                           ; Count both edges
    movlw   (1<<INTEDG)
    xorwf   OPTION_REG,F
    banksel BANK0
;
; The external interrupt is used to count
; pulses from the fan speed output.
;
    movf    Fan_PulseNoiseFilter,W
    movlw   1               
    skpz                                    ; skip if enough time since last pulse counted
    movlw   0               
    addwf   Isr_FanPulseCount,F                ; Increment fan speed pulse count
    skpnc
    addwf   Isr_FanPulseCount+1,F
    movlw   FAN_PULSE_FILTER_SYSTEM_TICKS   ; Start timeout between pulse counts to help
    addwf   Fan_PulseNoiseFilter,F          ; reject noise on fan speed pulse output.
ISR_INT_Done:
;
; Handle TIMER0 interrupts
;
ISR_TMR0:
    btfss   INTCON,TMR0IE                   ; Skip if TIMER0 interrupt is enabled
    goto    ISR_TMR0_Done
    btfss   INTCON,TMR0IF                   ; Skip if TIMER0 interrupt is asserted
    goto    ISR_TMR0_Done
;
    bcf     INTCON,TMR0IF                   ; Clear TIMER0 interrupt request

    bsf     STATUS,C
    movf    Fan_PulseNoiseFilter,W          ; Check if enough ticks since the last
    skpz                                    ; fans speed pulse has been counted.
    decfsz  Fan_PulseNoiseFilter,W          ; Decrement noise timeout counter when non-zero
    bcf     STATUS,C
    movwf   Fan_PulseNoiseFilter
    btfss   STATUS,C
    goto    ISR_TMR0_FilterDone
    bcf     INTCON,INTF                     ; Clear the external interrupt assert when rejecting noise
    bsf     INTCON,INTE                     ; Enable fan speed pulse counting while sample period is going
    bcf     PORTE,0                         ; toggle RE0 (DEBUG)
ISR_TMR0_FilterDone:
;
; Decrement the RPM period timeout
;
    movf    Rpm_CountTimeout+0,W            ; Test the Rpm_CountTimeout for zero and
    iorwf   Rpm_CountTimeout+1,W
    skpz                                    ; decrement it by one when it is not zero.
    movlw   -1
    addwf   Rpm_CountTimeout+0,F
    skpc
    addwf   Rpm_CountTimeout+1,F
    skpc
    bcf     INTCON,INTE
ISR_TMR0_RpmDone:
;
ISR_TMR0_Done:
;
    banksel BANK0
    movf    fsr_temp,W
    movwf   FSR
    movf    pclath_temp,W
    movwf   PCLATH
    movf    status_temp,w       ; retrieve copy of STATUS register
    movwf   STATUS              ; restore pre-isr STATUS register contents
    swapf   w_temp,f
    swapf   w_temp,w            ; restore pre-isr W register contents
    retfie                      ; return from interrupt
;
;**********************************************************************
; Initial the PIC to the Power On Reset state
;
start:
    clrf    INTCON              ; Disable all interrupt sources
    banksel BANK1
    clrf    PIE1
    clrf    PIE2

    movlw   b'11111111'         ;
    movwf   OPTION_REG

    movlw   b'11111111'         ;
    movwf   TRISA

    movlw   b'11111111'         ;
    movwf   TRISB

    movlw   b'11111111'         ;
    movwf   TRISC

    movlw   b'11111111'         ;
    movwf   TRISD

    movlw   b'00001100'         ; Make RE0 and output for debug
    movwf   TRISE

#ifdef __16F877A
    ; disable comparators
    movlw   b'00000111'
    movwf   CMCON
#endif

    ; Set all ADC inputs for digital I/O
    movlw   b'00000110'
    movwf   ADCON1

    banksel BANK0
    clrf    TMR0
    goto    main
;
;**********************************************************************
; Math support
;**********************************************************************
; Function: uMutiply_16x16
; Input:    A_reg, 16-bit multiplicand
;           B_reg, 16-bit multiplier
;
; Output:   D_reg, 32-bit product
;
; Notes:
;   The B_reg is overwritten by the low 16-bits of the product.
;
uMutiply_16x16:
    movlw   d'16'           ; Setup the number of bits to multiply
    movwf   mBits
    clrf    D_reg+2         ; Zero out the product register.
    clrf    D_reg+3
    clrc
    rrf     B_reg+1,F
    rrf     B_reg,F
uM16x16a:
    bnc     uM16x16b
    movf    A_reg,W         ; When CARRY is set then add 
    addwf   D_reg+2,F       ; the multiplicand to the product.
    movf    A_reg+1,W
    skpnc
    incfsz  A_reg+1,W
    addwf   D_reg+3,F
uM16x16b:
    rrf     D_reg+3,F       ; Shift in the CARRY from the add
    rrf     D_reg+2,F       ; and shift the product and multiplier
    rrf     D_reg+1,F       ; right one bit.
    rrf     D_reg+0,F
    decfsz  mBits,f         ; Decrement the bit count and loop
    goto    uM16x16a        ; until multiplication is complete.
    
    return
;
;**********************************************************************
; Function: Bin2BCD
; Input:    A_reg, 16-bit binary
;
; Output:   D_reg, 3 bytes of packed BCD digits
;
Bin2BCD:
    clrf    D_reg+0         ; Clear result
    clrf    D_reg+1
    clrf    D_reg+2
    movlw   D'16'           ; Set bit counter
    movwf   mBits

ConvertBit:
    movlw   0x33            ; Correct BCD value so that
    addwf   D_reg+0,F       ; subsequent shift yields
    btfsc   D_reg+0,.3      ; correct value.
    andlw   0xF0
    btfsc   D_reg+0,.7
    andlw   0x0F
    subwf   D_reg+0,F

    movlw   0x33
    addwf   D_reg+1,F
    btfsc   D_reg+1,.3
    andlw   0xF0
    btfsc   D_reg+1,.7
    andlw   0x0F
    subwf   D_reg+1,F

    rlf     A_reg+0,F       ; Shift out a binary bit
    rlf     A_reg+1,F

    rlf     D_reg+0,F       ; .. and into BCD value
    rlf     D_reg+1,F
    rlf     D_reg+2,F

    decfsz  mBits,F         ; Repeat for all bits
    goto    ConvertBit
    return     
;
;**********************************************************************
; PWM support
;**********************************************************************
; Function: Rpm_Init
; Description:
;   Setup the external INTerrupt to be used to
;   count fan speed pulses.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
Rpm_Init:
    bcf     INTCON,INTE         ; disable external interrupts
    banksel BANK1
    bsf     OPTION_REG,INTEDG   ; Select LOW to HIGH edge for INT assert
    banksel BANK0

    clrf    Isr_FanPulseCount      ; Clear RPM counter
    clrf    Isr_FanPulseCount+1
    return
;
;**********************************************************************
; Function: Rpm_Start
; Description:
;   Start a fan speed pulse count period.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
Rpm_Start:
    bcf     INTCON,INTE         ; disable external interrupts

    clrf    Isr_FanPulseCount      ; Clear RPM counter
    clrf    Isr_FanPulseCount+1

    movlw   LOW(RPM_COUNT_PERIOD)
    movwf   Rpm_CountTimeout
    movlw   HIGH(RPM_COUNT_PERIOD)
    movwf   Rpm_CountTimeout+1

    bcf     INTCON,INTF
    bsf     INTCON,INTE         ; enable external interrupts

    return
;
;**********************************************************************
; Function: Rpm_Status
; Description:
;   Check on the state of the RPM pulse count period.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  ZERO wheb the RPM capture period is complete
;
Rpm_Status:
    movf    Rpm_CountTimeout+0,W
    iorwf   Rpm_CountTimeout+1,W
    return
;
;**********************************************************************
; PWM support
;**********************************************************************
; Function: Pwm_Init
; Description:
;   Setup TIMER2 for PWM period and initialize
;   the CCP1 to produce a PWM output on pin RC2.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
Pwm_Init:
    banksel BANK1      
    bcf     PIE1,TMR2IE         ; Disable TIMER2 and CCP1 interruprs
    bcf     PIE1,CCP1IE
    bcf     TRISC,TRISC2        ; Make CCP1 an output
    banksel BANK0
    clrf    T2CON               ; Stop TIMER2
    clrf    CCP1CON             ; Stop PWM1
    movlw   PWM_PERIOD-1
    banksel BANK1
    movwf   PR2                 ; Setup PWM period
    banksel BANK0
    bsf     CCP1CON,CCP1M3
    bsf     CCP1CON,CCP1M2      ; Enable PWM
    clrf    CCPR1L              ; Make first PWM duty cycle 0%
    clrf    CCPR1H
    bsf     T2CON,TMR2ON        ; turn on PWM
    addlw   1                   ; WREG+CARRY = 25% duty cycle
    movwf   Pwm_DutyCycle+0
    clrf    Pwm_DutyCycle+1     ; Set initial duty cycle to 25%
    skpnc
    bsf     Pwm_DutyCycle+1,1
    goto    Pwm_SetDutyCycle
;
;**********************************************************************
; Function: Pwm_SetDutyCycle
; Description:
;   Move the Pwm_DutyCycle register to the PWM registers.
;   This is an insane amount of code to do this but it
;   is required because of the way the 10-bits of duty
;   cycle registers are mapped into the hardware.
;
; Inputs:   Pwm_DutyCycle
;
; Outputs:  none
;
; Returns:  nothing
;
; Notes:    Uses the FSR as temporary storage for bit rotates
;
Pwm_SetDutyCycle:
    rrf     Pwm_DutyCycle+1,W   ; Shift 10-bits of duty cycle right two bits
    rrf     Pwm_DutyCycle+0,W   ; to get them in to the proper positions
    movwf   FSR                 ; for the CCPRxL registers.
    clrc                        ;
    rrf     FSR,F               ; It is just weird that Microchip put these
    btfsc   Pwm_DutyCycle+1,1   ; bits in such a clumsy order.
    bsf     FSR,7
    swapf   Pwm_DutyCycle+0,W   ; Put 2-low duty cycle bits in proper position
    xorwf   CCP1CON,W           ; for the CCPxCON register.
    andlw   B'00110000'
    xorwf   CCP1CON,F           ; Update low 2-bits of PWM duty cycle
    movf    FSR,W
    movwf   CCPR1L              ; Update high 8-bits of PWM duty cycle

    return
;
;**********************************************************************
; Function: Pwm_DutyCycleUp
; Description:
;   Increments the PWM duty cycle up to 100%
;   and sets the hardware for the new duty cycle.
;
; Inputs:   Pwm_DutyCycle
;
; Outputs:  Pwm_DutyCycle
;
; Returns:  nothing
;
Pwm_DutyCycleUp:
    movf    Pwm_DutyCycle+0,W
    sublw   LOW (PWM_MAX_DUTY_CYCLE-1)
    movf    Pwm_DutyCycle+1,W
    skpc
    incfsz  Pwm_DutyCycle+1,W
    sublw   HIGH(PWM_MAX_DUTY_CYCLE-1)
    skpc
    return
    movlw   1
    addwf   Pwm_DutyCycle+0,F
    skpnc
    addwf   Pwm_DutyCycle+1,F
    goto    Pwm_SetDutyCycle
;
;**********************************************************************
; Function: Pwm_DutyCycleDown
; Description:
;   Decrements the PWM duty cycle down to 0%
;   and sets the hardware for the new duty cycle.
;
; Inputs:   Pwm_DutyCycle
;
; Outputs:  Pwm_DutyCycle
;
; Returns:  nothing
;
Pwm_DutyCycleDown:
    movf    Pwm_DutyCycle+0,W
    sublw   LOW (PWM_MIN_DUTY_CYCLE)
    movf    Pwm_DutyCycle+1,W
    skpc
    incfsz  Pwm_DutyCycle+1,W
    sublw   HIGH(PWM_MIN_DUTY_CYCLE)
    skpnc
    return
    movlw   0xFF
    addwf   Pwm_DutyCycle+0,F
    skpc
    addwf   Pwm_DutyCycle+1,F
    goto    Pwm_SetDutyCycle
;
;**********************************************************************
; LCD support
;**********************************************************************
;   This code assumes a oscillator of 8MHz
;
;   The the fastest oscillator a PIC16F877 can use is 20MHz.
;
;   When USE_FAST_CLOCK is defined the delays are adjusted
;   for a 20MHz oscillator.
;
#ifdef USE_FAST_CLOCK
#define DELAY_FOR_FAST_CLOCK  call DelayFor18TCY
#else
#define DELAY_FOR_FAST_CLOCK
#endif
;
;**********************************************************************
; Function: DelayFor18TCY
; Description:
;   Provides a 18 Tcy delay.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
DelayFor18TCY:
    goto    DelayFor16TCY

;
;**********************************************************************
; Function: DelayXLCD
; Description:
;   Provides at least 5ms delay.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
DelayXLCD:
;
; If we are using a fast clock make
; the delays work for a 20MHz clock.
;
#ifdef USE_FAST_CLOCK
    call    DXLCD0
    call    DXLCD0
    call    DXLCD0
    call    DXLCD0
#endif

DXLCD0:
    goto    $+1
    goto    $+1
    movlw   d'249'
DXLCD1:
    call    DelayFor16TCY
    addlw   -1
    bnz     DXLCD1
DelayFor16TCY:
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    return
;
;**********************************************************************
; Function: DelayPORXLCD
; Description:
;   Provides at least 15ms delay.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
DelayPORXLCD:
    call    DelayXLCD
    call    DelayXLCD
    goto    DelayXLCD
;
;**********************************************************************
; Function: LCD_Busy
; Description:
;   This routine reads the busy status of the
;   Hitachi HD44780 LCD controller.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  WREG = Not zero when status of LCD controller is busy
;
; Notes:
;  The busy bit is not reported in the same nibble
;  on all HD44780 "compatible" controllers.
;  If you have a Novatek 7605 type controller some
;  versions report these nibbles in reverse order.
;
;  This code has been tested with a Novatek 7605
;  and the real Hitachi HD44780.
;
LCD_Busy:
    movf    LCD_BusyBit,F   ; Check if busy bit avaliable.
    bz      DelayPORXLCD    ; Use a 15ms delay when busy not available.

    bcf     RS_PIN
    bsf     RW_PIN

    bcf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK

    btfsc   LCD_BusyBit,7
    movf    LCD_PORT,W      ; The standard LCD returns the BUSY flag first

    bcf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK

    btfsc   LCD_BusyBit,3
    movf    LCD_PORT,W      ; A Non standard LCD returns the BUSY flag second

    bcf     E_PIN
    andlw   (LCD_DATA_BITS&(~LCD_DATA_BITS>>1))
    bnz     LCD_Busy
    return
;
; Send a byte to LCD using 4-bit mode
LCD_PutByte:
    banksel BANK1
    movlw   ~LCD_DATA_BITS
    andwf   LCD_PORT,F      ; Make LCD port bits outputs
    banksel BANK0
    andwf   LCD_PORT,F      ; Make LCD port bits zero

    bcf     RW_PIN
;
; send first 4-bits
    swapf   LCD_byte,W
    andlw   LCD_DATA_BITS
    iorwf   LCD_PORT,F
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bcf     E_PIN
;
; send second 4-bits
    xorwf   LCD_byte,W
    andlw   LCD_DATA_BITS
    xorwf   LCD_PORT,F
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bcf     E_PIN

; set data bits for input
    banksel BANK1
    movlw   LCD_DATA_BITS
    iorwf   LCD_PORT,F
    banksel BANK0
    movf    LCD_byte,W
    return
;
; Read a byte to LCD using 4-bit mode
LCD_GetByte:
    bsf     RW_PIN
;
; read first 4-bits
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    movf    LCD_PORT,W
    bcf     E_PIN
    andlw   LCD_DATA_BITS
    movwf   LCD_byte
;
; read second 4-bits
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    movf    LCD_PORT,W
    bcf     E_PIN
    andlw   LCD_DATA_BITS
    swapf   LCD_byte,F
    iorwf   LCD_byte,F
    movf    LCD_byte,W
    return
;
;**********************************************************************
; Function Name:  LCD_SetCGRamAddr
; Description:
;   This routine sets the character generator
;   address of the Hitachi HD44780 LCD
;   controller.
;
; Inputs:   W = character generator ram address
;
; Outputs:  none
;
; Returns:  nothing
;
LCD_SetCGRamAddr:
    iorlw   0x40            ; Write cmd and address to port
    movwf   LCD_byte        ; save byte going to LCD

    call    LCD_Busy

    bcf     RS_PIN
    goto    LCD_PutByte

;
;**********************************************************************
; Function:  LCD_SetDDRamAddr
; Description:
;   This routine sets the display data address
;   of the Hitachi HD44780 LCD controller.
;
; Inputs:   W = display data address
;
; Outputs:  none
;
; Returns:  nothing
;
LCD_SetDDRamAddr:
    iorlw   0x80            ; Write cmd and address to port
    movwf   LCD_byte        ; save byte going to LCD

    call    LCD_Busy

    bcf     RS_PIN
    goto    LCD_PutByte
;
;**********************************************************************
; Function Name:  LCD_WriteCmd
; Description:
;   This routine writes a command to the Hitachi
;   HD44780 LCD controller.
;
; Inputs:   W = command to send to LCD
;
; Outputs:  none
;
; Returns:  nothing
;
LCD_WriteCmd:
    movwf   LCD_byte        ; save byte going to LCD

    call    LCD_Busy

    bcf     RS_PIN
    goto    LCD_PutByte
;
;**********************************************************************
; Function: LCD_WriteData
; Description:
;   This routine writes a data byte to the
;   Hitachi HD44780 LCD controller. The data
;   is written to the character generator RAM or
;   the display data RAM depending on what the
;   previous SetxxRamAddr routine was called.
;
; Inputs:   W = data to send to LCD
;
; Outputs:  none
;
; Returns:  nothing
;
LCD_WriteData:
    movwf   LCD_byte        ; save byte going to LCD

    call    LCD_Busy

    bsf     RS_PIN
    call    LCD_PutByte
    bcf     RS_PIN
    return
;
;**********************************************************************
; Function: LCD_Init
; Description:
;   This routine configures the LCD. Based on
;   the Hitachi HD44780 LCD controller. The
;   routine will configure the I/O pins of the
;   microcontroller, setup the LCD for 4-bit
;   mode and clear the display.
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
LCD_Init:
    clrf    LCD_BusyBit
    banksel BANK1
    movlw   ~LCD_DATA_BITS
    andwf   LCD_PORT,F      ; Make LCD data bus an output
    bcf     E_PIN           ; Make LCD data enable strobe an output
    bcf     RW_PIN          ; Make LCD Read/Write select an output
    bcf     RS_PIN          ; Make LCD Register select an output
    bcf     LCD_POWER_EN    ; Make LCD power enable an output
    banksel BANK0
    andwf   LCD_PORT,F      ; Drive all LCD pins low
    bcf     E_PIN
    bcf     RW_PIN
    bcf     RS_PIN
    bsf     LCD_POWER_EN    ; Turn on LCD power

    call    DelayPORXLCD    ; Wait for LCD to complete power on reset

    movlw   b'00000011'     ; force LCD into 8-bit mode
    iorwf   LCD_PORT,F
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bcf     E_PIN
    call    DelayXLCD       ; Required 5ms delay

    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bcf     E_PIN
    call    DelayXLCD       ; minimum 100us delay but use 5ms

    movlw   b'00000010'     ; set LCD into 4-bit mode
    xorwf   LCD_PORT,W
    andlw   LCD_DATA_BITS
    xorwf   LCD_PORT,F
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bcf     E_PIN
    call    DelayXLCD

    banksel BANK1
    movlw   LCD_DATA_BITS   ; Make LCD data pins inputs
    iorwf   LCD_PORT,F
    banksel BANK0

    movlw   LCD_FORMAT
    andlw   0x0F            ; Allow only 4-bit mode for
    iorlw   0x20            ; HD44780 LCD controller.
    call    LCD_WriteCmd

    movlw   (DOFF & CURSOR_OFF & BLINK_OFF)
    call    LCD_WriteCmd

    movlw   (DON & CURSOR_OFF & BLINK_OFF)
    call    LCD_WriteCmd

    movlw   (0x01)          ; Clear display
    call    LCD_WriteCmd

    movlw   (SHIFT_CUR_LEFT)
    call    LCD_WriteCmd
;
; Find position of busy bit
; Required when using 4-bit mode.
;
    movlw   LINE_ONE+1
    call    LCD_SetDDRamAddr

    call    LCD_Busy

    call    LCD_GetByte
    xorlw   0x01
    skpnz
    bsf     LCD_BusyBit,7
    xorlw   0x11
    skpnz
    bsf     LCD_BusyBit,3
;
; Initialize CGRAM
;
    clrw
    call    LCD_SetCGRamAddr
    movlw   LOW(CGRAM_Table)
    movwf   LCD_pszRomStr
    movlw   HIGH(CGRAM_Table)
    movwf   LCD_pszRomStr+1
    call    LCD_Putrs
;
; Put cursor on line one, left most position
;
    movlw   LINE_ONE
    call    LCD_SetDDRamAddr

    return
;
;**********************************************************************
; Function: LCD_PutHex
; Description:
;   Writes two ASCII character of the
;   hexadecimal value in thw WREG register.
;
; Inputs:   WREG = 8-bit value to convert to ASCII hex and send to the LCD
;
; Outputs:  none
;
; Returns:  nothing
;
LCD_PutHex:
        movwf   LCD_pszRomStr
        swapf   LCD_pszRomStr,W
        call    LCD_PutHexNibble
        movf    LCD_pszRomStr,W
LCD_PutHexNibble:
        andlw   0x0F
        addlw   0x06
        btfsc   STATUS,DC
        addlw   'A'-'0'-d'10'
        addlw   '0'-d'6'
        call    LCD_WriteData
        movf    LCD_pszRomStr,W
        return
;
;**********************************************************************
; Function: LCD_PutDec
; Description:
;   Writes two ASCII character of the
;   BCD value in thw WREG register.
;
; Inputs:   WREG = 8-bit BCD value to convert to ASCII and send to the LCD
;           CARRY = 1 suppress zero of MSD
;           DIGIT_CARRY = 1 suppress zero of LSD
;
; Outputs:  none
;
; Returns:  When either BCD digit is not zero then CARRY and DIGIT_CARRY are cleared
;
; Notes:
;   When sending multiple pairs of BCD digits with zero suppression start with
;   CARRY and DIGIT_CARRY set to one. For the last BCD digit pair always clear
;   the DIGIT_CARRY to zero. This will display the last digit when when the 
;   entire BCD number is all zeros.
;
;
LCD_PutDecLSD:
        movwf   LCD_pszRomStr       ; save digits to send
        swapf   STATUS,W            ; save zero suppression flags
        movwf   LCD_pszRomStr+1
        goto    LCD_PutDecLSDonly
        
LCD_PutDec:
        movwf   LCD_pszRomStr       ; save digits to send
        swapf   STATUS,W            ; save zero suppression flags
        movwf   LCD_pszRomStr+1
        swapf   LCD_pszRomStr,W
        andlw   0x0F
        btfsc   LCD_pszRomStr+1,4
        skpz                        ; Skip if digits is zero
        goto    LCD_PutDecMSDnz
        iorlw   ' '                 ; convert leading zero to space
        goto    LCD_PutDecMSDzero
LCD_PutDecMSDnz:
        bcf     LCD_pszRomStr+1,4   ; digit not zero so stop suppressing zeros in MSD
        bcf     LCD_pszRomStr+1,5   ; digit not zero so stop suppressing zeros in LSD
        iorlw   '0'                 ; Convert BCD digit to ASCII number
LCD_PutDecMSDzero:
        call    LCD_WriteData

LCD_PutDecLSDonly:        
        movf    LCD_pszRomStr,W
        andlw   0x0F
        btfsc   LCD_pszRomStr+1,5
        skpz                        ; Skip if digits is zero
        goto    LCD_PutDecLSDnz
        iorlw   ' '                 ; convert leading zero to space
        goto    LCD_PutDecLSDzero
LCD_PutDecLSDnz:
        bcf     LCD_pszRomStr+1,4   ; digit not zero so stop suppressing zeros in MSD
        bcf     LCD_pszRomStr+1,5   ; digit not zero so stop suppressing zeros in LSD
        iorlw   '0'                 ; Convert BCD digit to ASCII number
LCD_PutDecLSDzero:
        call    LCD_WriteData

        swapf   LCD_pszRomStr+1,W   ; Return state of zero suppression flags
        movwf   STATUS
        swapf   LCD_pszRomStr,F     ; Return 
        swapf   LCD_pszRomStr,W
        return
;
;**********************************************************************
; Function: LCD_Putrs
; Description:
;   This routine writes a string of bytes to the
;   Hitachi HD44780 LCD controller. The data
;   is written to the character generator RAM or
;   the display data RAM depending on what the
;   previous SetxxRamAddr routine was called.
;
; Inputs:   LCD_pszRomStr: pointer to string
;
; Outputs:  none
;
; Returns:  nothing
;
LCD_Putrs:
    call    TableLookUp
    iorlw   0
    skpnz
    return
    call    LCD_WriteData
    incf    LCD_pszRomStr,F
    skpnz
    incf    LCD_pszRomStr+1,F
    goto    LCD_Putrs

TableLookUp:
    movfw   LCD_pszRomStr+1
    movwf   PCLATH
    movfw   LCD_pszRomStr
    movwf   PCL
;
;**********************************************************************
; This table is used to write
; default characters to the
; Character Generator RAM of
; the LCD module.
;
CGRAM_Table:
    dt      B'10001000' ; CGRAM character 1
    dt      B'10000100'
    dt      B'10001110'
    dt      B'10000100'
    dt      B'10001000'
    dt      B'10000000'
    dt      B'10000000'
    dt      B'10011111'

    dt      B'10001110' ; CGRAM character 2
    dt      B'10010001'
    dt      B'10010000'
    dt      B'10010000'
    dt      B'10010001'
    dt      B'10001110'
    dt      B'10000000'
    dt      B'10011111'

    dt      B'10001110' ; CGRAM character 3
    dt      B'10010001'
    dt      B'10010000'
    dt      B'10010011'
    dt      B'10010001'
    dt      B'10001110'
    dt      B'10000000'
    dt      B'10011111'

    dt      B'10000000' ; CGRAM character 4
    dt      B'10001110'
    dt      B'10001010'
    dt      B'10001010'
    dt      B'10001110'
    dt      B'10000000'
    dt      B'10000000'
    dt      B'10011111'

    dt      B'10011110' ; CGRAM character 5
    dt      B'10010001'
    dt      B'10010001'
    dt      B'10011110'
    dt      B'10010010'
    dt      B'10010001'
    dt      B'10000000'
    dt      B'10011111'

    dt      B'10001110' ; CGRAM character 6
    dt      B'10010001'
    dt      B'10010001'
    dt      B'10011111'
    dt      B'10010001'
    dt      B'10010001'
    dt      B'10000000'
    dt      B'10011111'

    dt      B'10010001' ; CGRAM character 7
    dt      B'10011011'
    dt      B'10010101'
    dt      B'10010101'
    dt      B'10010001'
    dt      B'10010001'
    dt      B'10000000'
    dt      B'10011111'

    dt      B'10000100' ; CGRAM character 8
    dt      B'10001000'
    dt      B'10011100'
    dt      B'10001000'
    dt      B'10000100'
    dt      B'10000000'
    dt      B'10000000'
    dt      B'10011111'

    dt      B'00000000' ; End of table marker
;
;**********************************************************************
; UART support
;**********************************************************************
; Function: Uart_Init
; Description:
;   Setup the UART for asynchronous serial communication at
;   at 9600 baud, 8-Data bits, No parity, 1-Stop bit
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
Uart_Init:
    banksel BANK1               ; Disable UART interrupts
    bcf     PIE1,RCIE
    bcf     PIE1,TXIE

    banksel BANK0
    clrf    RCSTA               ; Reset reciever
    banksel BANK1
    clrf    TXSTA               ; Reset tarnsmitter
    bsf     TRISC,TRISC6        ; Make UART pins inputs
    bsf     TRISC,TRISC7
#if ( ((FCYC/(BAUD_RATE*4))-1) < d'256' )
  #if ( ((FCYC/(BAUD_RATE*4))-1) < 1 )
    error Baudrate out of range
  #else
    bsf     TXSTA,BRGH          ; Use high speed baudrate divisor
    movlw   (FCYC/(BAUD_RATE*4))-1
  #endif
#else
  #if ( ((FCYC/(BAUD_RATE*16))-1) < d'256' )
    bcf     TXSTA,BRGH          ; Use low speed baudrate divisor
    movlw   (FCYC/(BAUD_RATE*16))-1
  #else
    error Baudrate out of range
  #endif
#endif
    movwf   SPBRG               ; Set baudrate
    bsf     TXSTA,TXEN
    banksel BANK0
    bsf     RCSTA,CREN
    bsf     RCSTA,SPEN
    bcf     PIR1,RCIF
    bcf     PIR1,TXIF
#ifdef UART_ISR_ENABLED
    banksel BANK1               ; enable UART interrupts
    bsf     PIE1,RCIE
    bsf     PIE1,TXIE
    banksel BANK0
#endif
    return
;
;**********************************************************************
; Function: Uart_Getc
; Description:
;   Wait for the the UART transmitter to be ready
;   then sned the character in the WREG
;
; Inputs:   WREG = 8-bit value to send to the UART
;
; Outputs:  none
;
; Returns:  nothing
;
Uart_Putc:
    banksel BANK1
Uart_PutcWait:
    btfss   TXSTA,TRMT
    goto    Uart_PutcWait
    banksel BANK0
    movwf   TXREG
    return
;
;**********************************************************************
; Function: Uart_GetcStatus
; Description:
;   Get status of UART receiver
;   Returns non-ZERO when character is available
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  ZERO statis flag, WREG is changed.
;
Uart_GetcStatus:
    movf    PIR1,W
    andlw   (1<<RCIF)
    return
;
;**********************************************************************
; Function: Uart_Getc
; Description:
;   Wait for a character to arrive at the UART
;   then return the character in the WREG
;
; Inputs:   none
;
; Outputs:  WREG = 8-bit value received from the UART
;
; Returns:  nothing
;
Uart_Getc:
Uart_GetcWait:
    btfss   PIR1,RCIF
    goto    Uart_GetcWait
    btfsc   RCSTA,OERR
    goto    Uart_GetcOERR
    btfsc   RCSTA,FERR
    goto    Uart_GetcFERR
    movf    RCREG,W
    return
;
; Handle overrun error
;
Uart_GetcOERR:
    bcf     RCSTA,CREN
    bsf     RCSTA,CREN
    movf    RCREG,W
    movf    RCREG,W
    movf    RCREG,W
    goto    Uart_GetcWait
;
; Handle framing error
;
Uart_GetcFERR:
    movf    RCREG,W
    goto    Uart_GetcWait

;
;**********************************************************************
; Function: Uart_PutHex
; Description:
;   Writes two ASCII character of the
;   hexadecimal value in thw WREG register.
;
; Inputs:   WREG = 8-bit value to convert to ASCII hex and send to the UART
;
; Outputs:  none
;
; Returns:  nothing
;
Uart_PutHex:
        movwf   Uart_pszRomStr
        swapf   Uart_pszRomStr,W
        call    Uart_PutHexNibble
        movf    Uart_pszRomStr,W
Uart_PutHexNibble:
        andlw   0x0F
        addlw   0x06
        btfsc   STATUS,DC
        addlw   'A'-'0'-d'10'
        addlw   '0'-d'6'
        call    Uart_Putc
        movf    Uart_pszRomStr,W
        return
;
;**********************************************************************
; Function: Uart_PutDec
; Description:
;   Writes two ASCII character of the
;   BCD value in thw WREG register.
;
; Inputs:   WREG = 8-bit BCD value to convert to ASCII and send to the LCD
;           CARRY = 1 suppress zero of MSD
;           DIGIT_CARRY = 1 suppress zero of LSD
;
; Outputs:  none
;
; Returns:  When either BCD digit is not zero then CARRY and DIGIT_CARRY are cleared
;
; Notes:
;   When sending multiple pairs of BCD digits with zero suppression start with
;   CARRY and DIGIT_CARRY set to one. For the last BCD digit pair always clear
;   the DIGIT_CARRY to zero. This will display the last digit when when the 
;   entire BCD number is all zeros.
;
;
Uart_PutDecLSD:
        movwf   Uart_pszRomStr      ; save digits to send
        swapf   STATUS,W            ; save zero suppression flags
        movwf   Uart_pszRomStr+1
        goto    Uart_PutDecLSDonly
        
Uart_PutDec:
        movwf   Uart_pszRomStr      ; save digits to send
        swapf   STATUS,W            ; save zero suppression flags
        movwf   Uart_pszRomStr+1
        swapf   Uart_pszRomStr,W
        andlw   0x0F
        btfsc   Uart_pszRomStr+1,4
        skpz                        ; Skip if digit is zero
        goto    Uart_PutDecMSDnz
        iorlw   ' '                 ; convert leading zero to space
        goto    Uart_PutDecMSDzero
Uart_PutDecMSDnz:
        bcf     Uart_pszRomStr+1,4  ; digit not zero so stop suppressing zeros in MSD
        bcf     Uart_pszRomStr+1,5  ; digit not zero so stop suppressing zeros in LSD
        iorlw   '0'                 ; Convert BCD digit to ASCII number
Uart_PutDecMSDzero:
        call    Uart_Putc

Uart_PutDecLSDonly:
        movf    Uart_pszRomStr,W
        andlw   0x0F
        btfsc   Uart_pszRomStr+1,5  ; Skip when leading zero suppression is off
        skpz                        ; Skip if digit is zero
        goto    Uart_PutDecLSDnz
        movlw   ' '                 ; convert leading zero to space
        goto    Uart_PutDecLSDzero
Uart_PutDecLSDnz:
        bcf     Uart_pszRomStr+1,4  ; digit not zero so stop suppressing zeros in MSD
        bcf     Uart_pszRomStr+1,5  ; digit not zero so stop suppressing zeros in LSD
        iorlw   '0'                 ; Convert BCD digit to ASCII number
Uart_PutDecLSDzero:
        call    Uart_Putc

        swapf   Uart_pszRomStr+1,W   ; Return state of zero suppression flags
        movwf   STATUS
        swapf   Uart_pszRomStr,F     ; Return 
        swapf   Uart_pszRomStr,W
        return
;
;**********************************************************************
; Function: Uart_Putrs
; Description:
;   This routine writes a string of bytes to the
;   UART Asynchronous serial port.
;
; Inputs:   Uart_pszRomStr: pointer to string
;
; Outputs:  none
;
; Returns:  nothing
;
Uart_Putrs:
    call    Uart_TableLookUp
    iorlw   0
    skpnz
    return
    call    Uart_Putc
    incf    Uart_pszRomStr,F
    skpnz
    incf    Uart_pszRomStr+1,F
    goto    Uart_Putrs

Uart_TableLookUp:
    movfw   Uart_pszRomStr+1
    movwf   PCLATH
    movfw   Uart_pszRomStr
    movwf   PCL
;
;**********************************************************************
; Function: Tick_Init
; Description:
;   Initialize TIMER0 as the system tick interrupt
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
Tick_Init:
    bcf     INTCON,TMR0IE       ; Disable TIMER0 interrupts

    banksel BANK1
    bcf     OPTION_REG,T0CS     ; Set TIMER0 clock source to FCYC (oscillator frequency / 4)
    bcf     OPTION_REG,PSA      ; Assign prescaler to TIMER0
    bcf     OPTION_REG,PS2      ; Set TIMER0 prescale to 1:8
    bsf     OPTION_REG,PS1      ; TIMER0 will assert the overflow flag every 256*8 (2048)
    bcf     OPTION_REG,PS0      ; instruction cycles, with a 8MHz oscilator this ia 1.024 milliseconds.

    banksel BANK0
    clrf    TMR0
    bcf     INTCON,TMR0IF
    bsf     INTCON,TMR0IE       ; Enable TIMER0 interrupts

    return

;
;**********************************************************************
; Main application process loop
;
main:
    call    Tick_Init
    call    Uart_Init
    call    LCD_Init
    call    Pwm_Init
    call    Rpm_Init
    bsf     INTCON,PEIE
    bsf     INTCON,GIE
;
; Send initial message to UART
;
    movlw   LOW(Uart_message1)
    movwf   Uart_pszRomStr
    movlw   HIGH(Uart_message1)
    movwf   Uart_pszRomStr+1
    call    Uart_Putrs
;
    movlw   LINE_ONE
    call    LCD_SetDDRamAddr
    movlw   LOW(LCD_message1)
    movwf   LCD_pszRomStr
    movlw   HIGH(LCD_message1)
    movwf   LCD_pszRomStr+1
    call    LCD_Putrs
;
    movlw   LINE_TWO
    call    LCD_SetDDRamAddr
    movlw   LOW(LCD_message2)
    movwf   LCD_pszRomStr
    movlw   HIGH(LCD_message2)
    movwf   LCD_pszRomStr+1
    call    LCD_Putrs
;
ApplicationLoop:
    call    UartPwmCommandTest
    call    RpmTest
    goto    ApplicationLoop
;
; UART test of PWM command characters
;
;   When the UART rescives a '+' character increase the PWM duty cycle
;   When the UART rescives a '-' character decrease the PWM duty cycle
;
UartPwmCommandTest:
    call    Uart_GetcStatus
    skpnz
    return
    call    Uart_Getc
    xorlw   '+'
    skpnz
    goto    Pwm_DutyCycleUp
    xorlw   '+'
    xorlw   '-'
    skpnz
    goto    Pwm_DutyCycleDown
    return
;
; PWM test
;
;   Start a fan speed pulse count period
;   Report PWM duty cycle and fan speed in RPMs.
;
RpmTest:
    call    Rpm_Status
    skpz                        ; Skip if pulse count period complete
    return
    
    bcf     PORTE,1 ; debug
    movf    Isr_FanPulseCount+0,W   ; copy pulse count
    movwf   Rpm_FanPulseCount
    movf    Isr_FanPulseCount+1,W
    movwf   Rpm_FanPulseCount+1
    call    Rpm_Start           ; start next pulse count period

    movf    Pwm_DutyCycle+0,W   ; copy pulse count
    movwf   A_reg               ; to Bin2BCD binary register
    movf    Pwm_DutyCycle+1,W
    movwf   A_reg+1
    call    Bin2BCD

    movlw   'P'
    call    Uart_Putc
    movlw   'W'
    call    Uart_Putc
    movlw   'M'
    call    Uart_Putc
    movlw   ':'
    call    Uart_Putc
    bsf     STATUS,C
    bsf     STATUS,DC
    movf    D_reg+1,W
    call    Uart_PutDec
    bcf     STATUS,DC
    movf    D_reg+0,W
    call    Uart_PutDec
    movlw   ' '
    call    Uart_Putc

    movf    Rpm_FanPulseCount+0,W ; copy pulse count
    movwf   A_reg               ; to multiply register
    movf    Rpm_FanPulseCount+1,W
    movwf   A_reg+1

    call    Bin2BCD             ; Convert to BCD

    movlw   'C'
    call    Uart_Putc
    movlw   'N'
    call    Uart_Putc
    movlw   'T'
    call    Uart_Putc
    movlw   ':'
    call    Uart_Putc

    bsf     STATUS,C
    bsf     STATUS,DC
    movf    D_reg+2,W
    call    Uart_PutDecLSD
    movf    D_reg+1,W
    call    Uart_PutDec
    bcf     STATUS,DC
    movf    D_reg+0,W
    call    Uart_PutDec
    movlw   ' '
    call    Uart_Putc

    movf    Rpm_FanPulseCount+0,W ; copy pulse count
    movwf   A_reg               ; to multiply register
    movf    Rpm_FanPulseCount+1,W
    movwf   A_reg+1
    
    movlw   LOW (K1)            ; load RPM converion factor
    movwf   B_reg               ; in multiplier register
    movlw   HIGH(K1)
    movwf   B_reg+1

    call    uMutiply_16x16      ; Do the multiply to get RPM * 256

    movf    D_reg+1,W           ; Divide by 256
    movwf   A_reg+0
    movf    D_reg+2,W
    movwf   A_reg+1

    call    Bin2BCD             ; Convert to BCD

; Display the result on UART
    movlw   'R'
    call    Uart_Putc
    movlw   'P'
    call    Uart_Putc
    movlw   'M'
    call    Uart_Putc
    movlw   ':'
    call    Uart_Putc

    bsf     STATUS,C
    bsf     STATUS,DC
    movf    D_reg+2,W
    call    Uart_PutDecLSD
    movf    D_reg+1,W
    call    Uart_PutDec
    bcf     STATUS,DC
    movf    D_reg+0,W
    call    Uart_PutDec
    movlw   CR
    call    Uart_Putc
    movlw   LF
    call    Uart_Putc

; Display the result on LCD
    movlw   LINE_TWO+4          
    call    LCD_SetDDRamAddr
    bsf     STATUS,C
    bsf     STATUS,DC
    movf    D_reg+2,W
    call    LCD_PutDecLSD
    movf    D_reg+1,W
    call    LCD_PutDec
    bcf     STATUS,DC
    movf    D_reg+0,W
    call    LCD_PutDec

    movf    Rpm_FanPulseCount+0,W ; copy pulse count
    movwf   A_reg               ; to multiply register
    movf    Rpm_FanPulseCount+1,W
    movwf   A_reg+1
    call    Bin2BCD             ; Convert to BCD

    movlw   LINE_TWO+12         
    call    LCD_SetDDRamAddr
    bsf     STATUS,C
    bsf     STATUS,DC
    movf    D_reg+1,W
    call    LCD_PutDec
    bcf     STATUS,DC
    movf    D_reg+0,W
    call    LCD_PutDec

    bsf     PORTE,1 ;debug

    return
;
; Text messages
;
LCD_message1:
    dt  "Fan Speed - v1.0",0
LCD_message2:
    dt  "RPM:      C:    ",0
Uart_message1:
    dt  CR,LF
    dt  "UART PWM command ",CR,LF
    dt  "test:+=up, -=down",CR,LF,0

    end
