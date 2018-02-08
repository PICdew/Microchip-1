;
;                            PIC16F877A
;                    +-----------:_:-----------+
;         ICD_VPP -> :  1 MCLRn         PGD 28 : <> RB7 ICD_PGD
;             RA0 <> :  2 AN0           PGC 27 : <> RB6 ICD_PGC
;             RA1 <> :  3 AN1               26 : <> RB5
;             RA2 <> :  4 AN2               25 : <> RB4
;             RA3 <> :  5 AN3           PGM 24 : <> RB3
;             RA4 <> :  6 T0CKI             23 : <> RB2
;             RA5 <> :  7 AN4/SS            22 : <> RB1
;             GND <> :  8 VSS          INT0 21 : <> RB0
;      20MHz XTAL -> :  9 OSC1          VDD 20 : <- 5v0
;      20MHz XTAL <- : 10 OSC2          VSS 19 : <- GND
;      LCD_RS RC0 -> : 11 T1OSO          RX 18 : <> RC7
;      LCD_E  RC1 <> : 12 T1OSI          TX 17 : <> RC6
; MAX7219_DI  RC2 <> : 13 CCP1          SDO 16 : <> RC5 MAX7219_CLK
;             RC3 <> : 14 SCK/SCL   SDA/SDI 15 : <> RC4 MAX7219_CSn
;                    +-------------------------+
;                              DIP-28
;
        LIST    r=dec, n=0, c=160
        errorlevel -302         ; Suppress the not in bank zero warning
#INCLUDE "P16F876A.INC"


;MACROS


        __CONFIG        _BODEN_OFF & _CP_OFF & _CPD_OFF &_WRT_OFF & _PWRTE_OFF & _WDT_OFF & _LVP_OFF & _HS_OSC & _DEBUG_OFF

        LIST    P=16F876A

#define BANK0   H'000'
#define BANK1   H'080'
#define BANK2   H'100'
#define BANK3   H'180'

;RTC DEFINES---------------
#DEFINE DIN     PORTC,2
#DEFINE CLK     PORTC,5
#DEFINE LOAD    PORTC,4
;RTC DEFINES END-----------


;VARIABLES-------------------------
        CBLOCK  H'20'

SPI_TEMP
CHAR_TO_SEND

        ENDC


        ORG     0
                NOP
                GOTO    RESET


;MAX7219 SUBS----------------------------------------------------------------------------------
;
; Function: BB_SPI_TX
;
; Description:
;   Bit-Bang SPI transmit function.
;
; Input:    WREG = 8-bit to send to SPI device
;
; Output:   none
;
; Uses:     SPI_TEMP
;
#define SPI_MOSI_MASK (B'00000100')
BB_SPI_TX:
                MOVWF   SPI_TEMP
                RLF     SPI_TEMP,W
                XORWF   SPI_TEMP,F
                BSF     SPI_TEMP,0
                MOVLW   SPI_MOSI_MASK
                BCF     DIN             ; Clear PORTC bit 2
BB_SPI_TX1:
                BCF     CLK
                BTFSC   STATUS,C
                XORWF   PORTC,F         ; Update MOSI output bit
                BCF     STATUS,C
                RLF     SPI_TEMP,F
                BSF     CLK
                MOVF    SPI_TEMP,F
                BTFSS   STATUS,Z
                GOTO    BB_SPI_TX1
                BCF     CLK
                RETURN

;
; Function: SEND_ASCII
;
; Description:
;   Lookup ASCII character in 5x7 character generator table in code space
;   and send pattern to MAX7219.
;
; Input:    WREG = ASCII character.
;
; Output:   none
;
; Uses:
;
; Calls:    CG_SET_ADDRESS, CG_LOOK_UP, BB_SPI_TX
;
SEND_ASCII:
                CALL    CG_SET_ADDRESS

                CALL    MAX7219_SELECT
                MOVLW   D'2'            ; Row 1 of 5x7 pattern
                CALL    BB_SPI_TX
                CALL    CG_LOOK_UP      ; Send data
                CALL    BB_SPI_TX
                CALL    MAX7219_DESELECT

                CALL    MAX7219_SELECT
                MOVLW   D'3'            ; Row 2 of 5x7 pattern
                CALL    BB_SPI_TX
                CALL    CG_LOOK_UP      ; Send data
                CALL    BB_SPI_TX
                CALL    MAX7219_DESELECT

                CALL    MAX7219_SELECT
                MOVLW   D'4'            ; Row 3 of 5x7 pattern
                CALL    BB_SPI_TX
                CALL    CG_LOOK_UP      ; Send data
                CALL    BB_SPI_TX
                CALL    MAX7219_DESELECT

                CALL    MAX7219_SELECT
                MOVLW   D'5'            ; Row 4 of 5x7 pattern
                CALL    BB_SPI_TX
                CALL    CG_LOOK_UP      ; Send data
                CALL    BB_SPI_TX
                CALL    MAX7219_DESELECT

                CALL    MAX7219_SELECT
                MOVLW   D'6'            ; Row 5 of 5x7 pattern
                CALL    BB_SPI_TX
                CALL    CG_LOOK_UP      ; Send data
                CALL    BB_SPI_TX
                CALL    MAX7219_DESELECT

                RETURN
;
; Function: CG_SET_ADDRESS
;
; Description:
;   Set address for character generator lookup.
;   Multiply the ASCII character code by 5 and
;   add the based address of the look up table.
;
; Input:    WREG = ASCII character.
;
; Output:   EEADRH:EEADR set to first byte of data
;
CG_SET_ADDRESS:
                banksel BANK2
                MOVWF   EEADR
                CLRF    EEADRH
                CLRC
                RLF     EEADR,F
                RLF     EEADRH,F
                RLF     EEADR,F
                RLF     EEADRH,F
                ADDWF   EEADR,F
                BTFSC   STATUS,C
                INCF    EEADRH,F
                MOVLW   LOW(ASCII_CHAR_GEN)
                ADDWF   EEADR,F
                BTFSC   STATUS,C
                INCF    EEADRH,F
                MOVLW   HIGH(ASCII_CHAR_GEN)
                ADDWF   EEADRH,F
                banksel BANK0
                RETURN
;
; Function: CG_LOOK_UP
;
; Input:        Code space address in EEADRH:EEADR
;
; Output:       WREG = Low 8-bit at address
;               EEADRH:EEADR incremented
;
CG_LOOK_UP:
                banksel BANK3           ; Bank 3
                BSF     EECON1,EEPGD    ; Point to PROGRAM memory
                BSF     EECON1,RD       ; EE Read
                NOP                     ; 2-cycle wait
                NOP                     ; to read code space
                banksel BANK2
                MOVF    EEDATA,W        ; W = low 8-bits of data in program space
                INCF    EEADR,F         ; Increment to next address
                BTFSC   STATUS,Z
                INCF    EEADRH,F
                banksel BANK0
                RETURN
;
; Assert the SPI chip select for the MAX7219
;
MAX7219_SELECT:
                BCF     LOAD
                RETURN
;
; Deassert the SPI chip select for the MAX7219
;
MAX7219_DESELECT:
                BSF     LOAD
                NOP
                NOP
                NOP
                RETURN

;
; Function: MAX7219INIT
;
; Description:
;   Initialize MAX7219 LED Display driver
;
; Input:    none
;
; Output:   none
;
; Calls:    BB_SPI_TX, MAX7219_DESELECT
;
MAX7219INIT:
                CALL    MAX7219_DESELECT
                BCF     CLK

                CALL    MAX7219_SELECT
                MOVLW   H'0C'           ;SHUTDOWN COMMAND
                CAll    BB_SPI_TX
                MOVLW   H'01'           ;RELEASED
                CAll    BB_SPI_TX
                CALL    MAX7219_DESELECT

                CALL    MAX7219_SELECT
                MOVLW   H'09'           ;DECODE MODE COMMAND
                CAll    BB_SPI_TX
                MOVLW   D'0'            ;DISABLED FOR ALL DIGITS
                CAll    BB_SPI_TX
                CALL    MAX7219_DESELECT

                CALL    MAX7219_SELECT
                MOVLW   H'0A'           ;INTENSITY COMMAND
                CAll    BB_SPI_TX
                MOVLW   H'01'           ;INTENSITY VALUE
                CAll    BB_SPI_TX
                CALL    MAX7219_DESELECT

                CALL    MAX7219_SELECT
                MOVLW   H'0B'           ;SCAN LIMIT COMMAND
                CAll    BB_SPI_TX
                MOVLW   H'07'           ;ALL DIGITS
                CAll    BB_SPI_TX
                CALL    MAX7219_DESELECT

                CALL    MAX7219_SELECT
                MOVLW   H'0F'           ;TEST MODE COMMAND
                CAll    BB_SPI_TX
                MOVLW   D'0'            ;NORMAL
                CAll    BB_SPI_TX
                CALL    MAX7219_DESELECT

                MOVLW   D'1'            ; 
                CALL    ZERO_COLUMN
                MOVLW   D'2'            ; 
                CALL    ZERO_COLUMN
                MOVLW   D'3'            ; 
                CALL    ZERO_COLUMN
                MOVLW   D'4'            ; 
                CALL    ZERO_COLUMN
                MOVLW   D'5'            ; 
                CALL    ZERO_COLUMN
                MOVLW   D'6'            ; 
                CALL    ZERO_COLUMN
                MOVLW   D'7'            ; 
                CALL    ZERO_COLUMN
                MOVLW   D'8'            ; 
ZERO_COLUMN:
                CALL    MAX7219_SELECT
                CALL    BB_SPI_TX
                MOVLW   0
                CALL    BB_SPI_TX
                CALL    MAX7219_DESELECT

                RETURN


;MAX7219 SUBS ENDS-----------------------------------------------------------------------------
INIT
                CLRF    INTCON          ;DISABLE INTERUPTS
                CLRF    STATUS
                MOVLW   B'00000111'     ;DISABLE COMPS.
                MOVWF   CMCON           ;
                banksel BANK1           ;SELECT BANK1
                                        ;Disable pull-ups
                                        ;INT on rising edge
                                        ;TMR0 clock source is FOSC/4
                                        ;TMR0 Incr low2high trans.
                                        ;Prescaler assign to Timer0
                                        ;Prescaler rate is 1:256
                MOVLW   B'11010111'     ;Set PIC options (See datasheet).
                MOVWF   OPTION_REG      ;Write the OPTION register.
                MOVLW   D'6'
                MOVWF   ADCON1          ;SET PORT A AS DIGITAL I/O'S NOT AS AD CVONVERTORS
                                        ;START UP AS A/D PINS NOT AS DIGITAL I/O PINS WHY ?
                MOVLW   B'11111111'     ;
                MOVWF   TRISB           ;ALL PORT B OUTPUTS EXCEPT RB7 AND RB6, USED FOR ICD
                MOVLW   B'11000000'
                MOVWF   TRISC           ;ALL PORT C OUTPUTS EXCEPT RC7 AND RC6 USED FOR USART
                MOVLW   B'11011111'     ;ALL PORT A INPUTS  EXCEPT RA5
                MOVWF   TRISA
                banksel BANK0           ;SELECT BANK0
                CLRF    PORTB           ;PORTB CLEAR
                CLRF    PORTC           ;PORTC CLEAR
                MOVLW   B'00100000'     ;ASSERT MAX7219 LOAD PIN TO HIGH
                MOVWF   PORTA           ;PORTA CLEAR

                RETURN                  ;END OF SUB
;
; Function: DELAY
;
; Description:
;   Use TIMER0 to count cycles for a delay.
;
;   Delay: (4 * PRESCAL_VALUE * TIMER0_COUNT * WREG) / FOSC
;          (4 * 256           * 256          * 76  ) / 20000000 = 0.9961472 seconds
;
DELAY:
                MOVLW   D'76'
                BCF     INTCON,TMR0IF
DELAY_1:
                BTFSS   INTCON,TMR0IF
                GOTO    DELAY_1
                BCF     INTCON,TMR0IF
                ADDLW   -1
                BTFSS   STATUS,Z
                GOTO    DELAY_1
                RETURN

;------------------------------------------------------------------------------------------

RESET:
                CALL    INIT
                CALL    MAX7219INIT
SHOW_START:
                MOVLW   '!'
                MOVWF   CHAR_TO_SEND
SHOW_LOOP:
                MOVF    CHAR_TO_SEND,W
                CALL    SEND_ASCII
                CALL    DELAY
                INCF    CHAR_TO_SEND,F
                MOVLW   D'132'
                XORWF   CHAR_TO_SEND,W
                BTFSS   STATUS,Z
                GOTO    SHOW_LOOP
                GOTO    SHOW_START

;
; Reserved the last 0x500 instruction words (0x1B00 to 0x1FFF)
; of code space in page 3 for the ASCII character generator table.
;
        ORG     H'1B00'

ASCII_CHAR_GEN:
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII   0
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII   1
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII   2
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII   3
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII   4
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII   5
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII   6
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII   7
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII   8
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII   9
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  10
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  11
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  12
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  13
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  14
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  15
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  16
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  17
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  18
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  19
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  20
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  21
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  22
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  23
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  24
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  25
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  26
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  27
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  28
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  29
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  30
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII  31
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;SPACE  ASCII  32
                DW      B'00000000',B'00000000',B'11111010',B'00000000',B'00000000'  ;!      ASCII  33
                DW      B'00000000',B'11100000',B'00000000',B'11100000',B'00000000'  ;"      ASCII  34
                DW      B'00101000',B'11111110',B'00101000',B'11111110',B'00101000'  ;#      ASCII  35
                DW      B'01001000',B'01010100',B'11111110',B'01010100',B'00100100'  ;$      ASCII  36
                DW      B'01000110',B'00100110',B'00010000',B'11001000',B'11000100'  ;%      ASCII  37
                DW      B'00001010',B'01000100',B'10101010',B'10010010',B'01101100'  ;&      ASCII  38
                DW      B'00000000',B'00000000',B'11000000',B'00000000',B'00000000'  ;'      ASCII  39
                DW      B'00000000',B'10000010',B'01000100',B'00111000',B'00000000'  ;(      ASCII  40
                DW      B'00000000',B'00111000',B'01000100',B'10000010',B'00000000'  ;)      ASCII  41
                DW      B'01000100',B'00101000',B'11111110',B'00101000',B'01000100'  ;*      ASCII  42
                DW      B'00010000',B'00010000',B'01111100',B'00010000',B'00010000'  ;+      ASCII  43
                DW      B'00000000',B'00000000',B'00001100',B'00001010',B'00000000'  ;,      ASCII  44
                DW      B'00010000',B'00010000',B'00010000',B'00010000',B'00010000'  ;-      ASCII  45
                DW      B'00000000',B'00000000',B'00000110',B'00000110',B'00000000'  ;.      ASCII  46
                DW      B'01000000',B'00100000',B'00010000',B'00001000',B'00000100'  ;/      ASCII  47
                DW      B'01111100',B'10100010',B'10010010',B'10001010',B'01111100'  ;0      ASCII  48
                DW      B'00000010',B'00000010',B'11111110',B'01000010',B'00100010'  ;1      ASCII  49
                DW      B'01100010',B'10010010',B'10001010',B'10000110',B'01000010'  ;2      ASCII  50
                DW      B'01101100',B'10010010',B'10010010',B'10000010',B'01000100'  ;3      ASCII  51
                DW      B'00001000',B'11111110',B'01001000',B'00101000',B'00011000'  ;4      ASCII  52
                DW      B'10001100',B'10010010',B'10010010',B'10010010',B'11110100'  ;5      ASCII  53
                DW      B'00001100',B'10010010',B'10010010',B'01010010',B'00111100'  ;6      ASCII  54
                DW      B'11000000',B'10100000',B'10010000',B'10001110',B'10000000'  ;7      ASCII  55
                DW      B'01101100',B'10010010',B'10010010',B'10010010',B'01101100'  ;8      ASCII  56
                DW      B'01111000',B'10010100',B'10010010',B'10010010',B'01100000'  ;9      ASCII  57
                DW      B'00000000',B'00000000',B'01101100',B'01101100',B'00000000'  ;:      ASCII  58
                DW      B'00000000',B'00000000',B'01101100',B'01101010',B'00000000'  ;;      ASCII  59
                DW      B'00000000',B'10000010',B'01000100',B'00101000',B'00010000'  ;<      ASCII  60
                DW      B'00101000',B'00101000',B'00101000',B'00101000',B'00101000'  ;=      ASCII  61
                DW      B'00010000',B'00101000',B'01000100',B'10000010',B'00000000'  ;>      ASCII  62
                DW      B'01100000',B'10010000',B'10001010',B'10000000',B'01000000'  ;?      ASCII  63
                DW      B'01111100',B'10000010',B'10011110',B'10010010',B'01001100'  ;@      ASCII  64
                DW      B'01111110',B'10010000',B'10010000',B'10010000',B'01111110'  ;A      ASCII  65
                DW      B'01101100',B'10010010',B'10010010',B'10010010',B'11111110'  ;B      ASCII  66
                DW      B'01000100',B'10000010',B'10000010',B'10000010',B'01111100'  ;C      ASCII  67
                DW      B'01111100',B'10000010',B'10000010',B'10000010',B'11111110'  ;D      ASCII  68
                DW      B'10000010',B'10010010',B'10010010',B'10010010',B'11111110'  ;E      ASCII  69
                DW      B'10000000',B'10010000',B'10010000',B'10010000',B'11111110'  ;F      ASCII  70
                DW      B'01001110',B'10001010',B'10000010',B'10000010',B'01111100'  ;G      ASCII  71
                DW      B'11111110',B'00010000',B'00010000',B'00010000',B'11111110'  ;H      ASCII  72
                DW      B'10000010',B'10000010',B'11111110',B'10000010',B'10000010'  ;I      ASCII  73
                DW      B'11111100',B'00000010',B'00000010',B'00000010',B'00000100'  ;J      ASCII  74
                DW      B'10000010',B'01000100',B'00101000',B'00010000',B'11111110'  ;K      ASCII  75
                DW      B'00000010',B'00000010',B'00000010',B'00000010',B'11111110'  ;L      ASCII  76
                DW      B'11111110',B'01000000',B'00110000',B'01000000',B'11111110'  ;M      ASCII  77
                DW      B'11111110',B'00001000',B'00010000',B'00100000',B'11111110'  ;N      ASCII  78
                DW      B'01111100',B'10000010',B'10000010',B'10000010',B'01111100'  ;O      ASCII  79
                DW      B'01100000',B'10010000',B'10010000',B'10010000',B'11111110'  ;P      ASCII  80
                DW      B'01111010',B'10000100',B'10001010',B'10000010',B'01111100'  ;Q      ASCII  81
                DW      B'01100010',B'10010100',B'10011000',B'10010000',B'11111110'  ;R      ASCII  82
                DW      B'01001100',B'10010010',B'10010010',B'10010010',B'01100100'  ;S      ASCII  83
                DW      B'10000000',B'10000000',B'11111110',B'10000000',B'10000000'  ;T      ASCII  84
                DW      B'11111100',B'00000010',B'00000010',B'00000010',B'11111100'  ;U      ASCII  85
                DW      B'11100000',B'00011000',B'00000110',B'00011000',B'11100000'  ;V      ASCII  86
                DW      B'11111100',B'00000010',B'00011100',B'00000010',B'11111100'  ;W      ASCII  87
                DW      B'11000110',B'00101000',B'00010000',B'00101000',B'11000110'  ;X      ASCII  88
                DW      B'11000000',B'00100000',B'00011110',B'00100000',B'11000000'  ;Y      ASCII  89
                DW      B'11000010',B'10100010',B'10010010',B'10001010',B'10000110'  ;Z      ASCII  90
                DW      B'00000000',B'00000000',B'10000010',B'10000010',B'11111110'  ;[      ASCII  91
                DW      B'00000100',B'00001000',B'00010000',B'00100000',B'01000000'  ;\      ASCII  92
                DW      B'00000000',B'00000000',B'11111110',B'10000010',B'10000010'  ;]      ASCII  93
                DW      B'00100000',B'01000000',B'10000000',B'01000000',B'00100000'  ;^      ASCII  94
                DW      B'00000010',B'00000010',B'00000010',B'00000010',B'00000010'  ;_      ASCII  95
                DW      B'00000000',B'00100000',B'01000000',B'10000000',B'00000000'  ;`      ASCII  96
                DW      B'00011110',B'00101010',B'00101010',B'00101010',B'00000100'  ;a      ASCII  97
                DW      B'00011100',B'00100010',B'00100010',B'00010010',B'11111110'  ;b      ASCII  98
                DW      B'00000100',B'00100010',B'00100010',B'00100010',B'00011100'  ;c      ASCII  99
                DW      B'11111110',B'00010010',B'00100010',B'00100010',B'00011100'  ;d      ASCII 100
                DW      B'00011000',B'00101010',B'00101010',B'00101010',B'00011100'  ;e      ASCII 101
                DW      B'01000000',B'10000000',B'10010000',B'01111110',B'00010000'  ;f      ASCII 102
                DW      B'01111100',B'01001010',B'01001010',B'01001010',B'00110000'  ;g      ASCII 103
                DW      B'00011110',B'00100000',B'00100000',B'00010000',B'11111110'  ;h      ASCII 104
                DW      B'00000000',B'00000010',B'10111110',B'00100010',B'00000000'  ;i      ASCII 105
                DW      B'00000000',B'10111100',B'00100010',B'00000010',B'00000100'  ;j      ASCII 106
                DW      B'00000000',B'00100010',B'00010100',B'00001000',B'11111110'  ;k      ASCII 107
                DW      B'00000000',B'00000010',B'11111110',B'10000010',B'00000000'  ;l      ASCII 108
                DW      B'00011110',B'00100000',B'00011000',B'00100000',B'00111110'  ;m      ASCII 109
                DW      B'00011110',B'00100000',B'00100000',B'00010000',B'00111110'  ;n      ASCII 110
                DW      B'00011100',B'00100010',B'00100010',B'00100010',B'00011100'  ;o      ASCII 111
                DW      B'00010000',B'00101000',B'00101000',B'00101000',B'00111110'  ;p      ASCII 112
                DW      B'00111110',B'00011000',B'00101000',B'00101000',B'00010000'  ;q      ASCII 113
                DW      B'00010000',B'00100000',B'00100000',B'00010000',B'00111110'  ;r      ASCII 114
                DW      B'00000100',B'00101010',B'00101010',B'00101010',B'00010010'  ;s      ASCII 115
                DW      B'00000100',B'00000010',B'00100010',B'11111100',B'00100000'  ;t      ASCII 116
                DW      B'00111110',B'00000100',B'00000010',B'00000010',B'00111100'  ;u      ASCII 117
                DW      B'00111000',B'00000100',B'00000010',B'00000100',B'00111000'  ;v      ASCII 118
                DW      B'00111100',B'00000010',B'00001100',B'00000010',B'00111100'  ;w      ASCII 119
                DW      B'00100010',B'00010100',B'00001000',B'00010100',B'00100010'  ;x      ASCII 120
                DW      B'00111100',B'00001010',B'00001010',B'00001010',B'00110000'  ;y      ASCII 121
                DW      B'00100010',B'00110010',B'00101010',B'00100110',B'00100010'  ;z      ASCII 122
                DW      B'10000010',B'01101100',B'00010000',B'00000000',B'00000000'  ;{      ASCII 123
                DW      B'00000000',B'00000000',B'11111110',B'00000000',B'00000000'  ;|      ASCII 124
                DW      B'00000000',B'00010000',B'01101100',B'10000010',B'00000000'  ;}      ASCII 125
                DW      B'11001100',B'11000010',B'00010010',B'11000010',B'11001100'  ;SMILE  ASCII 126 USER DEFINEABLE CHARS START HERE UNTIL 255
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII 127 USED AS MESSAGE END DONT USE
                DW      B'11000100',B'11000100',B'00010100',B'11000100',B'11000100'  ;SOSO   ASCII 128
                DW      B'11111110',B'11111110',B'11111110',B'11111110',B'11111110'  ;       ASCII 129
                DW      B'11111110',B'10000010',B'10000010',B'10000010',B'11111110'  ;       ASCII 130
                DW      B'11000110',B'11001000',B'00011000',B'11001000',B'11000110'  ;SAD    ASCII 131
                DW      B'00000000',B'00000000',B'00000000',B'00000000',B'00000000'  ;       ASCII 132

                END
