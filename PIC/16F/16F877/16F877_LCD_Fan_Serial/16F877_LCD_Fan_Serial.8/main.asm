; 
; File: main.asm
; Target: PIC16F877A or PIC16F877
; IDE: MPLAB v8.92
; Compiler: MPASMWIN v5.51
;
; -------------------------
; Main application
; -------------------------
#define MAIN_ASM
#include "main.inc"
#include "math.inc"
#include "tick.inc"
#include "pwm.inc"
#include "lcd.inc"
#include "uart.inc"
#include "rpm.inc"
#include "buttons.inc"
;
;                         PIC16F877A
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
;   PICDEM 2 Plus:
;   RD0 <> LCD_D4    Special note that the LCD module on my PICDEM2 PLUS
;   RD1 <> LCD_D5    is a NOVATEK 7605. In 4-bit mode the NOVATEK 7605 is 
;   RD2 <> LCD_D6    not 100% compatible with the Hitachi HD44780. The 
;   RD3 <> LCD_D7    issue is that in 4-bit mode a status read returns the 
;   RD4 -> LCD_RS    4-bits in an order that is different from the HD44780.
;   RD5 -> LCD_R/W   
;   RD6 -> LCD_E   
;   RD7 -> LCD_ON  
;
;------------------------------------------------------------------------
;
;
;
MAIN_DATA udata
LcdTestCount        res 1


MAIN_CODE code
; 
; This is the LCD test application.
;
; First open the LCD with a 4-bit 
; interface 5x7 character size
; and more than one line.
;
main:
    lcall   Tick_Init
    lcall   Pwm_Init
    lcall   Rpm_Init
    lcall   LCD_Init
    lcall   Uart_Init
    lcall   Button_Init
    bsf     INTCON,PEIE
    bsf     INTCON,GIE
;
; Send initial message to UART
;
    movlw   LOW(Uart_message1)
    movwf   Uart_pszRomStr
    movlw   HIGH(Uart_message1)
    movwf   Uart_pszRomStr+1
    lcall   Uart_Putrs
    
    lgoto   LcdTest

;
; LCD test
;
; Start by sending two lines to the LCD:
;   Line1: LCD test Ver 1.0
;   Line2:                 
;
; Then wait for a key event then display
; the LCD character set 16 characters at
; a time for each key event.
;
LcdTest:
    movlw   LINE_ONE
    lcall   LCD_SetDDRamAddr

    movlw   LOW(LCD_message4)
    movwf   LCD_pszRomStr
    movlw   HIGH(LCD_message4)
    movwf   LCD_pszRomStr+1
    lcall   LCD_putrs
;
; Blank second line of LCD
;
LcdTestRestart:
    movlw   LINE_TWO
    lcall   LCD_SetDDRamAddr

    movlw   LOW(LCD_message6)
    movwf   LCD_pszRomStr
    movlw   HIGH(LCD_message6)
    movwf   LCD_pszRomStr+1
    lcall   LCD_putrs

    movlw   LINE_TWO+D'14'
    lcall   LCD_SetDDRamAddr
    movf    LCD_BusyBit,W
    lcall   LCD_PutHex

    banksel LcdTestCount
    clrf    LcdTestCount
;
; Wait for key event.
;
TestLoop:
    lcall   UartPwmCommandTest
    lcall   RpmTest
    lcall   Button_GetStatus
    pagesel TestLoop
    skpnz
    goto    TestLoop
    xorlw   BUTTON_S2_CHANGE_MASK | BUTTON_S2_STATE_MASK
    skpnz
    goto    LcdTestNextState
    goto    TestLoop
;
;
;
UartPwmCommandTest:
    lcall   Uart_GetcStatus
    skpnz
    return
    lcall   Uart_Getc
    pagesel Pwm_DutyCycleUp
    xorlw   '+'
    skpnz
    goto    Pwm_DutyCycleUp
    xorlw   '+'
    xorlw   '-'
    skpnz
    goto    Pwm_DutyCycleDown
    return

;
; Display 16 character on LCD line 2.
;
LcdTestNextState:
    movlw   LINE_ONE
    lcall   LCD_SetDDRamAddr

    movlw   LOW(LCD_message5)
    movwf   LCD_pszRomStr
    movlw   HIGH(LCD_message5)
    movwf   LCD_pszRomStr+1
    lcall   LCD_putrs

    movlw   LINE_ONE+D'9'
    lcall   LCD_SetDDRamAddr
    banksel LcdTestCount
    movf    LcdTestCount,W
    lcall   LCD_PutDec
    movlw   '-'
    lcall   LCD_WriteData
    movf    LcdTestCount,W
    addlw   D'15'
    lcall   LCD_PutDec

    movlw   LINE_TWO
    lcall   LCD_SetDDRamAddr
LcdTestWriteLoop:
    banksel LcdTestCount
    movf    LcdTestCount,W
    lcall   LCD_WriteData

    pagesel TestLoop
    banksel LcdTestCount
    incf    LcdTestCount,F
    movf    LcdTestCount,W
    andlw   0x0F
    skpz
    goto    LcdTestWriteLoop
    goto    TestLoop
;
;
;
#define K1 (D'15000')
RpmTest:
    lcall   Rpm_Status
    skpz
    return

    bankisel Pwm_DutyCycle  ; copy pulse count
    movlw   Pwm_DutyCycle   ; to Bin2BCD binary register
    movwf   FSR
    movf    INDF,W
    banksel A_reg
    movwf   A_reg
    incf    FSR,F
    movf    INDF,W
    movwf   A_reg+1
    lcall   Bin2BCD

    movlw   'P'
    lcall   Uart_Putc
    movlw   'W'
    call    Uart_Putc
    movlw   'M'
    call    Uart_Putc
    movlw   ':'
    call    Uart_Putc
    bankisel D_reg
    movlw   D_reg+1
    movwf   FSR
    movf    INDF,W
    call    Uart_PutHex
    decf    FSR,F
    movf    INDF,W
    call    Uart_PutHex
    movlw   ' '
    call    Uart_Putc

    bankisel Rpm_PulseCount ; copy pulse count
    movlw   Rpm_PulseCount  ; to multiply register
    movwf   FSR
    movf    INDF,W
    banksel B_reg
    movwf   B_reg
    incf    FSR,F
    movf    INDF,W
    movwf   B_reg+1

    banksel A_reg
    movlw   LOW (K1)        ; load RPM converion factor
    movwf   A_reg           ; in multiplier register
    movlw   HIGH(K1)
    movwf   A_reg+1

    lcall   uMutiply_16x16  ; Do the multiply to get RPM * 256

    movf    D_reg+1,W       ; Divide by 256
    movwf   A_reg+0
    movf    D_reg+2,W
    movwf   A_reg+1
    lcall   Bin2BCD         ; Convert to BCD

    movlw   'R'
    lcall   Uart_Putc
    movlw   'P'
    call    Uart_Putc
    movlw   'M'
    call    Uart_Putc
    movlw   ':'
    call    Uart_Putc

    bankisel D_reg          ; Display the result
    movlw   D_reg+2
    movwf   FSR
    movf    INDF,W
    lcall   Uart_PutHex
    decf    FSR,F
    movf    INDF,W
    call    Uart_PutHex
    decf    FSR,F
    movf    INDF,W
    call    Uart_PutHex
    movlw   CR
    call    Uart_Putc
    movlw   LF
    call    Uart_Putc

    lcall   Rpm_Start       ; start next pulse count period

    return
;
; Text messages
;
MAIN_CONST   code
LCD_message_BlankLine:
    dt  "                ",0
LCD_message4:
    dt  "LCD test Ver 1.2",0
LCD_message5:
    dt  "Symbols:        ",0
LCD_message6:
    dt  "BusyBitMask:0x  ",0
Uart_message1:
    dt  CR,LF
    dt  "UART PWM command ",CR,LF
    dt  "test:+=up, -=down",CR,LF,0

    END
