; 
; File: main.asm
; Target: PIC16F690
; IDE: MPLAB v8.92
; Compiler: MPASMWIN v5.51
;
; -------------------------
; Main application
; -------------------------
#define MAIN_ASM
#include "main.inc"
#include "led.inc"
#include "lcd.inc"
#include "keypad.inc"
#include "onewire.inc"
;
; Project started on 2016/04/14 17:14:47
;
; http://ww1.microchip.com/downloads/en/DeviceDoc/40001262F.pdf
; http://www.storm-interface.com/storm-720gfx-series-16-button.html
; http://media.digikey.com/pdf/Data%20Sheets/Varitronix%20PDFs/MDL%28S%29-16465.pdf
; http://media.digikey.com/pdf/Data%20Sheets/Varitronix%20PDFs/Varitronix%20LCD%20Initialization%20Instructions.pdf
; http://www.vishay.com/docs/91300/91300.pdf
; https://en.wikipedia.org/wiki/1-Wire
; http://datasheets.maximintegrated.com/en/ds/DS2413.pdf
; http://datasheets.maximintegrated.com/en/ds/DS18B20.pdf
; http://datasheets.maximintegrated.com/en/ds/DS1923.pdf
; http://datasheets.maximintegrated.com/en/ds/DS1922L-DS1922T.pdf
; http://pdfserv.maximintegrated.com/en/an/AN2420.pdf
; http://pdfserv.maximintegrated.com/en/an/AN937.pdf
; http://pdfserv.maximintegrated.com/en/an/AN187.pdf
; http://pdfserv.maximintegrated.com/en/an/AN126.pdf
; https://www.maximintegrated.com/en/products/ibutton/software/1wire/wirekit.cfm
; http://files.maximintegrated.com/sia_bu/public/owpd310r2.zip
; https://en.wikipedia.org/wiki/Computation_of_cyclic_redundancy_checks
; http://www.108relays.ca/dl/1_Wire_Design_Guide_v1.0.pdf
; http://www.atmel.com/images/doc2579.pdf
; http://www.ti.com/lit/an/spma057a/spma057a.pdf
; http://www.ti.com/general/docs/lit/getliterature.tsp?baseLiteratureNumber=spma057&fileType=zip
; http://ww1.microchip.com/downloads/en/AppNotes/01199a.pdf
; http://ww1.microchip.com/downloads/en/AppNotes/1-Wire%20App%20Note%20Source%20Code.zip
;;
;                           PIC16F690
;                   +----------:_:----------+
;         PWR ->  1 : VDD               VSS : 20 <- GND
;      1-WIRE <>  2 : RA5/T1CKI     PGD/RA0 : 19 <> PGD
;         LED <-  3 : RA4           PGC/RA1 : 18 <> PGC
;         VPP ->  4 : RA3/VPP     T0CKI/RA2 : 17 <> LCD_E
;        KP_4 <>  5 : RC5               RC0 : 16 <> KP_1    LCD_D4  
;        KP_3 <>  6 : RC4               RC1 : 15 <> KP_2    LCD_D5  
; LCD_D7 KP_8 <>  7 : RC3               RC2 : 14 <> KP_7    LCD_D6  
;        KP_5 <>  8 : RC6               RB4 : 13 <> LCD_R/W
;        KP_6 <>  9 : RC7           RXD/RB5 : 12 <> RXD
;         TXD <> 10 : RB7/TXD           RB6 : 11 <> LCD_RS
;                   +-----------------------:
;                            DIP-20
;
;   PICDEM 2 Plus:
;   D0 <> LCD_D4    Special note that the LCD module on my PICDEM2 PLUS
;   D1 <> LCD_D5    is a NOVATEK 7605. In 4-bit mode the NOVATEK 7605 is 
;   D2 <> LCD_D6    not 100% compatible with the Hitachi HD44780. The 
;   D3 <> LCD_D7    issue is that in 4-bit mode a status read returns the 
;   D4 -> LCD_RS    4-bits in an order that is different from the HD44780.
;   D5 -> LCD_R/W   
;   D6 -> LCD_E     
;
;------------------------------------------------------------------------
MAIN_DATA udata
#define WAIT_TIME (d'1000')
WaitToProbe     res 2
owDetect        res 1
kpKeyTestCount  res 1
lcdTestCount    res 1

MAIN_CODE code
; 
; This is the LCD test application.
;
; First open the LCD with a 4-bit 
; interface 5x7 character size
; and more than one line.
;
main:
    lcall   ldInit
    lcall   kpInit
    movlw   (FOUR_BIT&LINES_5X7)
    lcall   OpenXLCD

    lgoto   lcdTest
;    lgoto   kpTest
;    lgoto   owTest

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
lcdTest:
    movlw   LINE_ONE
    lcall   SetDDRamAddr

    movlw   LOW(LCD_message4)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message4)
    movwf   pszLCD_RomStr+1
    lcall   putrsXLCD
;
; Blank second line of LCD
;
lcdTestRestart:
    movlw   LINE_TWO
    lcall   SetDDRamAddr

    movlw   LOW(LCD_message_BlankLine)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message_BlankLine)
    movwf   pszLCD_RomStr+1
    lcall   putrsXLCD

    banksel lcdTestCount
    clrf    lcdTestCount
;
; Wait for key event.
;
; Display 16 character on LCD line 2.
;
lcdTestLoop:
    lcall   kpGetStatus
    pagesel lcdTestLoop
    skpnz
    goto    lcdTestContinue
    andlw   KP_KEY_DOWN_MASK
    skpnz
    goto    lcdTestContinue

    movlw   LINE_ONE
    lcall   SetDDRamAddr

    movlw   LOW(LCD_message5)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message5)
    movwf   pszLCD_RomStr+1
    lcall   putrsXLCD

    movlw   LINE_ONE+D'14'
    lcall   SetDDRamAddr
    banksel lcdTestCount
    movf    lcdTestCount,W
    lcall   PutHexXLCD

    movlw   LINE_TWO
    lcall   SetDDRamAddr
lcdTestWriteLoop:
    banksel lcdTestCount
    movf    lcdTestCount,W
    lcall   WriteDataXLCD
    pagesel lcdTestLoop

    banksel lcdTestCount
    incf    lcdTestCount,F
    movf    lcdTestCount,W
    andlw   0x0F
    skpz
    goto    lcdTestWriteLoop
lcdTestContinue:
    btfss   INTCON,T0IF
    goto    lcdTestLoop
    bcf     INTCON,T0IF
    lcall   kpPoll
    lgoto   lcdTestLoop
;
; Matrix keypad test
;
;
; Then send two lines to the LCD:
;   Line1: Keypad   Ver 1.0
;   Line2:                 
;
kpTest:
    movlw   LINE_ONE
    lcall   SetDDRamAddr

    movlw   LOW(LCD_message3)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message3)
    movwf   pszLCD_RomStr+1
    lcall   putrsXLCD
;
; Blank second line of LCD
;
kpKeyTestRestart:
    movlw   LINE_TWO
    lcall   SetDDRamAddr

    movlw   LOW(LCD_message_BlankLine)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message_BlankLine)
    movwf   pszLCD_RomStr+1
    lcall   putrsXLCD

    movlw   LINE_TWO
    lcall   SetDDRamAddr

    movlw   D'17'
    banksel kpKeyTestCount
    movwf   kpKeyTestCount
;
; Display 16 key events.
;
; On the 17th event, discard the event, 
; blank line 2, then restart test.
;
kpTestLoop:
    lcall   kpGetStatus
    pagesel kpTestLoop
    skpnz
    goto    kpTestContinue
    andlw   KP_KEY_DOWN_MASK
    skpnz
    goto    kpTestContinue
    lcall   ldToggle
    lcall   kpGetKey
    pagesel kpTestLoop
    banksel kpKeyTestCount
    decf    kpKeyTestCount,F
    skpnz
    goto    kpKeyTestRestart
    lcall   WriteDataXLCD
    lgoto   kpTestLoop
kpTestContinue:
    btfss   INTCON,T0IF
    goto    kpTestLoop
    bcf     INTCON,T0IF
    lcall   kpPoll
    lgoto   kpTestLoop
;
; Test code for 1-Wire interface
;
;
; Then send two lines to the LCD:
;   Line1: OneWire  Ver 1.0
;   Line2: Device Not Found
;
owTest:
    movlw   LINE_ONE
    lcall   SetDDRamAddr

    movlw   LOW(LCD_message1)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message1)
    movwf   pszLCD_RomStr+1
    lcall   putrsXLCD

    banksel owDetect
    clrf    owDetect                    ; Initialize detect state to unknown
    decf    owDetect,F

FindOneWireDevices:
    lcall   owReset
    pagesel FindOneWireDevices
    banksel owDetect
    xorwf   owDetect,W
    xorwf   owDetect,F
    iorlw   0
    skpz
    call    ShowDevceStatus
    banksel WaitToProbe
    movlw   LOW(WAIT_TIME-1)
    movwf   WaitToProbe
    movlw   HIGH(WAIT_TIME-1)
    movwf   WaitToProbe+1

FindOneWireDevicesWait:
    movlw   d'250'-d'27'
    lcall    owWait18Cyc_Plus_W
    pagesel FindOneWireDevices
    movlw   0xFF
    banksel WaitToProbe
    addwf   WaitToProbe,F
    skpc
    addwf   WaitToProbe+1,F
    skpnc
    goto    FindOneWireDevicesWait
    goto    FindOneWireDevices

ShowDevceStatus:
    banksel owDetect
    btfss   owDetect,0
    goto    DeviceNotFound

DeviceFound:
    movlw   LINE_TWO
    lcall   SetDDRamAddr

    movlw   LOW(LCD_message_BlankLine)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message_BlankLine)
    movwf   pszLCD_RomStr+1
    lcall   putrsXLCD

    bsf     PORTB,7
    movlw   d'250'-d'18'
    lcall   owWait18Cyc_Plus_W
    movlw   d'250'-d'18'
    lcall   owWait18Cyc_Plus_W
    bcf     PORTB,7

    movlw   READ_ROM
    lcall   owWriteByte

    movlw   LINE_TWO
    lcall   SetDDRamAddr
    lcall   owReadByte
    lcall   PutHexXLCD      ; Family code

    movlw   LINE_TWO+d'12'
    lcall   SetDDRamAddr
    lcall   owReadByte
    lcall   PutHexXLCD      ; Serial Number byte 0

    movlw   LINE_TWO+d'10'
    lcall   SetDDRamAddr
    lcall   owReadByte
    lcall   PutHexXLCD      ; Serial Number byte 1

    movlw   LINE_TWO+d'8'
    lcall   SetDDRamAddr
    lcall   owReadByte
    lcall   PutHexXLCD      ; Serial Number byte 2

    movlw   LINE_TWO+d'6'
    lcall   SetDDRamAddr
    lcall   owReadByte
    lcall   PutHexXLCD      ; Serial Number byte 3

    movlw   LINE_TWO+d'4'
    lcall   SetDDRamAddr
    lcall   owReadByte
    lcall   PutHexXLCD      ; Serial Number byte 4

    movlw   LINE_TWO+d'2'
    lcall   SetDDRamAddr
    lcall   owReadByte
    lcall   PutHexXLCD      ; Serial Number byte 5

    movlw   LINE_TWO+d'14'
    lcall   SetDDRamAddr
    lcall   owReadByte
    lcall   PutHexXLCD      ; CRC
    pagesel DeviceFound
    return

DeviceNotFound:
    movlw   LINE_TWO
    lcall   SetDDRamAddr

    movlw   LOW(LCD_message2)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message2)
    movwf   pszLCD_RomStr+1
    lcall   putrsXLCD
    pagesel DeviceFound
    return

;
; LCD messages
;
MAIN_CONST   code
LCD_message_BlankLine:
    dt  "                ",0
LCD_message1:
    dt  "OneWire  Ver 1.0",0
LCD_message2:
    dt  "Device Not Found",0
LCD_message3:
    dt  "Keypad   Ver 1.0",0
LCD_message4:
    dt  "LCD test Ver 1.2",0
LCD_message5:
    dt  "Character row   ",0
    END
