;
; File: main.asm
; Target: PIC16F690
; IDE: MPLABX 2.35
; Assembler: MPASM v5.61
;
; Additional files:
;   P16F690.INC
;   16F690_g.lkr
;
; Description:
;   System clock is the Fast Internal Oscillato at 8MHz.
;
;   See Technical Bulletin: TB097 for circuit diagram.
;
;   Wait for serial input on PORTA bit 1, the PGC pin.
;   By default display the ADC value once per second.
;   When a byte is received it is checked for these charactders:
;       'A' - Toggle the display of the ADC value
;   Note: Characters are case sensitive and are UPPER CASE.
;
;   Data is sent using a bit-bang UART on PORTA bit 0, PGD.
;   The LED DS1 is on during UART send.
;
; http://www.microchip.com/developmenttools/productdetails.aspx?partno=pg164120
; http://ww1.microchip.com/downloads/en/DeviceDoc/Low%20Pin%20Count%20User%20Guide%2051556a.pdf
; http://ww1.microchip.com/downloads/en/DeviceDoc/LPC%20Demo%20Board%20Schematic.pdf
; http://www.mouser.com/Search/Refine.aspx?Keyword=DM164120-1
; http://ww1.microchip.com/downloads/en/AppNotes/91097A.pdf
;
; Notes:
;   LPC demo board modified to remove RP1 to remove 10K ohm load on VDD.
;   LPC demo board modified to add 32.768KHz crystal to pins 2 and 3.
;
    list p=16F690
#include "p16F690.inc"

    list    r=dec
    errorlevel -302

     __CONFIG _FOSC_INTRCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF

#define FOSC (8000000)
#define FCYC (FOSC/4)

#define BAUD (9600)
#define T0_RELOAD (256-(FCYC/BAUD))

#define T1_2SEC 0x0E

RESET_VECTOR CODE  0x000
        pagesel start
        goto    start

ISR_DATA    UDATA
WREG_SAVE   res     1
STATUS_SAVE res     1
PCLATH_SAVE res     1
;
; Application wide status flags
App_Status  res     1
#define RX_DataAvailable App_Status,1
#define RX_FamingError App_Status,2
#define RX_OverrunError App_Status,3
#define ADC_Sample App_Status,4
#define ADC_Show_Sample App_Status,5
;
; Serial data
TX_Data     res     1
RX_Data     res     1
UART_State  res     1

#define TX_START    (11)
#define RX_START    (16)
#define TXD_BIT     PORTA,0
#define RXD_BIT     PORTA,1
;
; ADC data
ADC_Value   res     2
;
; Process ADC delay
ADC_Delay   res     2
#define ADC_DELAY_COUNT (50000)

ISR_VECTOR  CODE    0x004
        movwf   WREG_SAVE
        movf    STATUS,W
        clrf    STATUS
        movwf   STATUS_SAVE
        movf    PCLATH,W
        movwf   PCLATH_SAVE
        clrf    PCLATH
;
; TIMER0 ISR
;   This is a bit banged half duplex UART
;
; Note:
;   The TIMER0 interrupt uses a PC relative
;   jump table to process the transmitter state.
;   This jump table must be within a 256 byte
;   program memory page.
;
ISR_TMR0:
        btfsc   INTCON,T0IE
        btfss   INTCON,T0IF
        goto    ISR_IOC

        bcf     INTCON,T0IF
        movlw   T0_RELOAD+3
        addwf   TMR0,F

        decfsz  UART_State,W      ; skip if transmitter is empty
        goto    UART_DoState
;
; TX empty
;
TX_State_0:
        bcf     INTCON,T0IE     ; Disable interrupt when TX empty
;
; Stop bit
;
TX_State_1:
        bsf     TXD_BIT
        goto    ISR_Exit

UART_DoState:
        andlw   0x0F            ; This prevents a crash but does not prevent
        movwf   UART_State      ; data errors when UART_state is corrupted.
        addwf   PCL,F
        goto    TX_State_0      ; TX empty
        goto    TX_State_1      ; stop
        goto    TX_State_2      ; data 7
        goto    TX_State_3      ; data 6
        goto    TX_State_4      ; data 5
        goto    TX_State_5      ; data 4
        goto    TX_State_6      ; data 3
        goto    TX_State_7      ; data 2
        goto    TX_State_8      ; data 1
        goto    TX_State_9      ; data 0
        goto    TX_State_10     ; start
        goto    TX_State_1      ; stop
        goto    TX_State_1      ; stop
        goto    TX_State_1      ; stop
        goto    RX_State_0      ; RX Stop bit
        goto    RX_State_1      ; RX Data bit
;
; Start bit
;
TX_State_10:
        bcf     TXD_BIT
        goto    ISR_Exit
;
; Data bits
;
TX_State_9:
TX_State_8:
TX_State_7:
TX_State_6:
TX_State_5:
TX_State_4:
TX_State_3:
TX_State_2:
        btfss   TX_Data,0
        bcf     TXD_BIT
        btfsc   TX_Data,0
        bsf     TXD_BIT
        rrf     TX_Data,F
        goto    ISR_Exit
;
; RX Stop bit
;
RX_State_0:
        btfss   RXD_BIT         ; Skip if stop bit present
        bsf     RX_FamingError
        btfsc   RX_DataAvailable ; Skip if data buffer available
        bsf     RX_OverrunError
        bsf     RX_DataAvailable ; Assert new data arrived
        bcf     INTCON,T0IE     ; Disable interrupt when RX complete
        goto    ISR_Exit
;
; RX Data bit
;
RX_State_1:
        btfsc   RXD_BIT         ; CARRY always zero when state starts
        setc                    ; Set CARRY if RX data is ZERO
        rrf     RX_Data,F       ; Shift in bit
        skpc                    ; CARRY is set when all 8 bits arrived
        incf    UART_State,F    ; Stay in RX data bit state until byte received
        goto    ISR_Exit

;
; Interrupt On Change ISR
;   This is a bit banged UART receive start bit
ISR_IOC:
        btfsc   INTCON,RABIE
        btfss   INTCON,RABIF
        goto    IOC_Exit

        movf    PORTA,W         ; Clear miss match
        bcf     INTCON,RABIF    ; Clear IOC assert
        btfsc   RXD_BIT         ; Skip if RXD is a Start Bit (LOW)
        goto    ISR_Exit

        movlw   T0_RELOAD+30    ; Add start bit ISR overhead
        movwf   TMR0
        bcf     INTCON,T0IF
        bsf     INTCON,T0IE

        movlw   0x80            ; Set to receive 8 bits of RX data
        movwf   RX_Data
        movlw   RX_START        ; Set UART to receive data bits state
        movwf   UART_State
        bcf     INTCON,RABIE    ; Disable RX start bit interrupt

        goto    ISR_Exit
IOC_Exit:
;
; Handle ADC interrupt
;
ISR_ADC:
        banksel PIE1        ; Bank 1
        btfss   PIE1,ADIE   ; must be enabled to wake from sleep
        goto    ADC_Exit

        banksel PIR1        ; Bank 0
        btfss   PIR1,ADIF   ; must be enabled to wake from sleep
        goto    ADC_Exit
        bcf     PIR1,ADIF
        btfss   ADC_Sample
        bsf     ADC_Sample
        goto    ISR_Exit
ADC_Exit:

ISR_Exit:
        movf    PCLATH_SAVE,W
        movwf   PCLATH
        movf    STATUS_SAVE,W
        movwf   STATUS
        swapf   WREG_SAVE,F
        swapf   WREG_SAVE,W
        retfie
;
; PutC
;   put a character out serial port
;
Putc:
        btfsc   INTCON,T0IE     ; skip when UART not busy
        goto    Putc
        bcf     INTCON,RABIE    ; cannot receive when sending

        banksel TX_Data
        movwf   TX_Data
        movlw   TX_START        ; select UART start send state
        movwf   UART_State

        banksel TMR0        ; Bank 0
        movlw   T0_RELOAD
        movwf   TMR0
        bcf     INTCON,T0IF
        bsf     INTCON,T0IE

        return
;
; Put HEX nibble
;
PutHexNibble:
        call    GetHexChar
        call    Putc
        return
;
; Look up ASCII character to low 4-bits in W
; Input: HEX nibble low 4-bits of W
; Output: W = ASCII character of HEX value
;
GetHexChar:
        andlw   0x0F
        movwf   PCLATH
        xorlw   HIGH(HexTable)
        xorwf   PCLATH,F
        xorlw   HIGH(HexTable)
        addlw   LOW(HexTable)
        skpnc
        incf    PCLATH,F
        movwf   PCL
HexTable:
        DT      '0','1','2','3','4','5','6','7'
        DT      '8','9','A','B','C','D','E','F'


MAIN_CODE CODE
;
; Do a very simple command processor
;
ProcessCharacter:
        bcf     RX_DataAvailable

        movlw   'A'             ; see if it is a toggle ADC display request
        xorwf   RX_Data,W
        skpnz
        call    ToggleAdcDisplay
;
; Enable RX start bit detect
;
EnableStartBitDetect:
        movf    PORTA,W
        bcf     INTCON,RABIF
        bsf     INTCON,RABIE
        return
;
; Turn the ADC display on or off
;
ToggleAdcDisplay:
        clrc
        btfss   ADC_Show_Sample
        setc
        skpc
        bcf     ADC_Show_Sample
        skpnc
        bsf     ADC_Show_Sample
        return
;
; Process ADC sample
;
ProcessAdcSample:
        banksel ADCON0
        btfsc   ADCON0,GO   ; Skip if ADC conversion is complete
        return
;
; Delay between ADC outputs because
; if we send too fast the UART receiver
; gets no cycles to detect a start bit.
;
        banksel ADC_Delay
        movf    ADC_Delay,W
        iorwf   ADC_Delay+1,W
        skpnz
        goto    DisplayAdcSample
        decf    ADC_Delay,F
        skpnz
        decf    ADC_Delay+1,F
        return

DisplayAdcSample:
;
; Reload delay count
;
        movlw   LOW(ADC_DELAY_COUNT)
        movwf   ADC_Delay
        movlw   HIGH(ADC_DELAY_COUNT)
        movwf   ADC_Delay+1
;
; Read all 10-bits of the ADC
;
        banksel ADRESL
        movf    ADRESL,W
        banksel ADC_Value
        movwf   ADC_Value

        banksel ADRESH
        movf    ADRESH,W
        banksel ADC_Value
        movwf   ADC_Value+1

        bcf     ADC_Sample          ; Clear process flag for ADC

        btfss   ADC_Show_Sample
        return

        call    ShowAdc             ; Display ADC value
        call    EnableStartBitDetect
        return
;
; Wait for UART transmit to complete
;
WaitForSend:
        btfsc   INTCON,T0IE     ; skip when UART not busy
        goto    WaitForSend
        return
;
; Display ADC value
;
ShowAdc:
        bsf     PORTC,0     ; Turn DS1 on

        swapf   ADC_Value+1,W
        call    PutHexNibble
        movf    ADC_Value+1,W
        call    PutHexNibble
        swapf   ADC_Value,W
        call    PutHexNibble
        movf    ADC_Value,W
        call    PutHexNibble

        movlw   0x0D
        call    Putc
        movlw   0x0A
        call    Putc

        call    WaitForSend

        bcf     PORTC,0     ; Turn DS1 off.

        return
;
; Power On Reset starts here
;
start:
;
; Set internal oscillator to 8 MHz
;
        banksel OSCCON
        movlw   0x70
        movwf   OSCCON      ; Set internal oscillator to 8MHz

        banksel INTCON      ; Bank 0
        clrf    INTCON      ; Disable interrupts
;
; Set all outputs to zero
;
        movlw   0x01
        movwf   PORTA       ; Set TXD high
        clrf    PORTB
        clrf    PORTC

        banksel ANSEL       ; Bank 2
        clrf    ANSEL
        bsf     ANSEL,2     ; Assign RA2 to ADC
        clrf    ANSELH
        clrf    WPUB        ; Disable PORTB pull-ups
        clrf    IOCB        ; Mask Interrupt On Change bits of PORTB

        banksel OPTION_REG  ; Bank1
        movlw   0x5F        ; Set OPTION register
        movwf   OPTION_REG  ; TIMER0 clocks source is FCYC

        clrf    PIE1        ; Clear all peripheral
        clrf    PIE2        ; interrupt enables.
        clrf    WPUA        ; Disable PORTA pull-ups
        clrf    IOCA        ; Mask Interrupt On Change bits of PORTA
        bsf     WPUA,1      ; Enable pull up on RXD (RA1)
        bsf     IOCA,1      ; Enable interrupt on change of RXD (RA1)

;
; Set all GPIOs directions, unused are outputs
;
        movlw   0x06        ; Set RA1, RA2 as input
        movwf   TRISA
        movlw   0x00
        movwf   TRISB
        movlw   0x00
        movwf   TRISC
;
; Initialize UART state
;
        banksel UART_State
        bcf     INTCON,T0IE
        clrf    UART_State
;
; Initialize application status flags
;
        clrf    App_Status
;
; Setup ADC
;
        movlw   0x70        ; We will be asleep for the ADC conversion
        banksel ADCON1      ; Bank 1
        movwf   ADCON1
        bsf     PIE1,ADIE   ; must be enabled to wake from sleep

        movlw   0x89        ; Select AN2 as ADC input
        banksel ADCON0      ; Bank 0
        movwf   ADCON0
        bcf     PIR1,ADIF
        bsf     INTCON,PEIE
;
; We wake from sleep because the TIMER1 interrupt
; request is asserted.
;
        bsf     PORTC,0     ; Start with LED ON
        bsf     INTCON,GIE
;
; Show the ADC value by default
;
        bsf     ADC_Show_Sample
;
; Print the initial message: "Start<CR><LF>"
;
        bsf     PORTC,0     ; Turn DS1 on.
        movlw   'S'
        call    Putc
        movlw   't'
        call    Putc
        movlw   'a'
        call    Putc
        movlw   'r'
        call    Putc
        movlw   't'
        call    Putc
        movlw   0x0D
        call    Putc
        movlw   0x0A
        call    Putc
        call    WaitForSend
        bcf     PORTC,0     ; Turn DS1 off.
;
; Start waiting for character
;
        call    EnableStartBitDetect
;
; This is the main process loop
;
ProcessLoop:
;
; Check process flags and sleep when idle
;
        btfsc   INTCON,T0IE
        goto    ProcessAwake    ; do not sleep when UART is running

        btfsc   RX_DataAvailable
        goto    ProcessAwake    ; do not sleep when UART RX data is available

        btfsc   ADC_Sample
        goto    ProcessAwake    ; do not sleep when ADC is sampling

        bsf     ADCON0,GO       ; start an ADC conversion
        sleep                   ; sleep and wait for an interrupt
        nop
        nop
;
; Process loop is awake
;
ProcessAwake:
        btfsc   RX_DataAvailable
        call    ProcessCharacter

        btfsc   ADC_Sample
        call    ProcessAdcSample

        goto    ProcessLoop

        end

