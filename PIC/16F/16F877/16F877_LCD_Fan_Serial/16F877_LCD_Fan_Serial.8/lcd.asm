; -------------------------
; LCD functions
; -------------------------
;
#define LCD_ASM
#include "main.inc"
#include "lcd.inc"
;
; This code assumes a oscillator of 8MHz
;
; The the fastest oscillator a PIC16F877A can use is 20MHz.
;
; When USE_FAST_CLOCK is defined the delays are adjusted
; for a 20MHz oscillator.
;
;#define USE_FAST_CLOCK
#ifdef USE_FAST_CLOCK  
#define DELAY_FOR_FAST_CLOCK  call DelayFor18TCY
#else
#define DELAY_FOR_FAST_CLOCK
#endif
;
; This RAM is used by the LCD interface routines.
;
; Warning:
;   This implementation depends on the shared memory space.
;   It will not work for PIC16F873/PIC16F874/PIC16F873A/PIC16F874A.
;
LCD_DATA    UDATA_SHR
LCD_byte    res     1       ; byte sent to or read from LCD
LCD_BusyBit res     1       ; Mask of where the BUSY bit is located
LCD_pszRomStr res   2       ; pointer to ASCIIZ string in ROM

LCD_CODE code

; DelayFor18TCY() provides a 18 Tcy delay
DelayFor18TCY:
    goto    DelayFor16TCY

; DelayXLCD() provides at least 5ms delay
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

; DelayPORXLCD() provides at least 15ms delay
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
#ifdef LCD_POWER_EN
    bcf     LCD_POWER_EN    ; Make LCD power enable an output
#endif
    banksel BANK0
    andwf   LCD_PORT,F      ; Drive all LCD pins low
    bcf     E_PIN
    bcf     RW_PIN
    bcf     RS_PIN
#ifdef LCD_POWER_EN
    bsf     LCD_POWER_EN    ; Turn on LCD power
#endif

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
; Turn display off
;
    movlw   (DOFF & CURSOR_OFF & BLINK_OFF)
    call    LCD_WriteCmd
;
; Turn display on
;
    movlw   (DON & CURSOR_OFF & BLINK_OFF)
    call    LCD_WriteCmd
;
; Clear display
;
    movlw   (0x01)          ; Clear display
    call    LCD_WriteCmd
;
; Set cursor shift direction
;
    movlw   (SHIFT_CUR_LEFT)
    call    LCD_WriteCmd
;
; Initialize CGRAM
;
    clrw    
    call    LCD_SetCGRamAddr
    movlw   LOW(CGRAM_Table)
    movwf   LCD_pszRomStr
    movlw   HIGH(CGRAM_Table)
    movwf   LCD_pszRomStr+1
    call    LCD_putrs
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
        goto    LCD_PutDecMSD_Skip
LCD_PutDecMSDnz:
        bcf     LCD_pszRomStr+1,4   ; digit not zero so stop suppressing zeros in MSD
        bcf     LCD_pszRomStr+1,5   ; digit not zero so stop suppressing zeros in LSD
        iorlw   '0'                 ; Convert BCD digit to ASCII number
LCD_PutDecMSDzero:
        call    LCD_WriteData
LCD_PutDecMSD_Skip:

LCD_PutDecLSDonly:        
        movf    LCD_pszRomStr,W
        andlw   0x0F
        btfsc   LCD_pszRomStr+1,5
        skpz                        ; Skip if digits is zero
        goto    LCD_PutDecLSDnz
        goto    LCD_PutDecLSD_Skip
LCD_PutDecLSDnz:
        bcf     LCD_pszRomStr+1,4   ; digit not zero so stop suppressing zeros in MSD
        bcf     LCD_pszRomStr+1,5   ; digit not zero so stop suppressing zeros in LSD
        iorlw   '0'                 ; Convert BCD digit to ASCII number
LCD_PutDecLSDzero:
        call    LCD_WriteData
LCD_PutDecLSD_Skip:

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
LCD_putrs:
    call    TableLookUp
    pagesel LCD_putrs
    iorlw   0
    skpnz
    return
    call    LCD_WriteData
    incf    LCD_pszRomStr,F
    skpnz
    incf    LCD_pszRomStr+1,F
    goto    LCD_putrs
    
TableLookUp:
    movfw   LCD_pszRomStr+1
    movwf   PCLATH
    movfw   LCD_pszRomStr
    movwf   PCL
;
; This table is used to write
; default characters to the 
; Character Generator RAM of
; the LCD module.
;
LCD_CONST   code
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

    end
