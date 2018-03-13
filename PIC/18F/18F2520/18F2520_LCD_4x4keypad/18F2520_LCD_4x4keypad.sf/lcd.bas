//
// File:   lcd.c
// Author:
//
// Target: PIC18F24K20, PIC18F2520
//
Module lcd

Include "init_h.bas"
#define _LCD_DATA_BITS   = $F0
Const LCD_DATA_BITS = _LCD_DATA_BITS

// Define the LCD port pins
Public Dim
    E_PIN               As LATA.bits(5),
    RW_PIN              As LATA.bits(4),
    RS_PIN              As LATA.bits(3),
    LCD_PORT_IN         As PORTC,
    LCD_PORT_OUT        As LATC

Public Dim
    E_PIN_DIR           As TRISA.bits(5),
    RW_PIN_DIR          As TRISA.bits(4),
    RS_PIN_DIR          As TRISA.bits(3),
    LCD_PORT_DIR        As TRISC

// Clear display command
Public Const CLEAR_DISPLAY = %00000001

// Return home command
Public Const RETURN_HOME = %00000010

// Display ON/OFF Control defines
Public Const DON         = %00001111    // Display on
Public Const DOFF        = %00001011    // Display off
Public Const CURSOR_ON   = %00001111    // Cursor on
Public Const CURSOR_OFF  = %00001101    // Cursor off
Public Const BLINK_ON    = %00001111    // Cursor Blink
Public Const BLINK_OFF   = %00001110    // Cursor No Blink

// Cursor or Display Shift defines
Public Const SHIFT_CUR_LEFT    = %00010011    // Cursor shifts to the left
Public Const SHIFT_CUR_RIGHT   = %00010111    // Cursor shifts to the right
Public Const SHIFT_DISP_LEFT   = %00011011    // Display shifts to the left
Public Const SHIFT_DISP_RIGHT  = %00011111    // Display shifts to the right

// Function Set defines
Public Const FOUR_BIT   = %00101111    // 4-bit Interface
Public Const EIGHT_BIT  = %00111111    // 8-bit Interface
Public Const LINE_5X7   = %00110011    // 5x7 characters, single line
Public Const LINE_5X10  = %00110111    // 5x10 characters
Public Const LINES_5X7  = %00111011    // 5x7 characters, multiple line

// Start address of each line
Public Const LINE_ONE    = $00
Public Const LINE_TWO    = $40

// Define the LCD interface and character size
Public Const LCD_FORMAT = FOUR_BIT And LINES_5X7

#if (_LCD_DATA_BITS = $0F)
  #define LCD_DATA_ON_LOW_4_BITS
#else
  #if (_LCD_DATA_BITS = $F0)
    #define LCD_DATA_ON_HIGH_4_BITS
  #else
    #error "LCD interface supports 4-bit mode only on high or low 4-bits of one port"
  #endif
#endif

Dim LCD_BusyBit As Byte

Const CGRAM_Table() As Byte =
(
    %10000000, // CGRAM character 1
    %10000100,
    %10000010,
    %10001111,
    %10000010,
    %10000100,
    %10000000,
    %10011111,

    %10001110, // CGRAM character 2
    %10010001,
    %10010000,
    %10010000,
    %10010001,
    %10001110,
    %10000000,
    %10011111,

    %10001110, // CGRAM character 3
    %10010001,
    %10010000,
    %10010011,
    %10010001,
    %10001110,
    %10000000,
    %10011111,

    %10000000, // CGRAM character 4
    %10001110,
    %10001010,
    %10001010,
    %10001110,
    %10000000,
    %10000000,
    %10011111,

    %10011110, // CGRAM character 5
    %10010001,
    %10010001,
    %10011110,
    %10010010,
    %10010001,
    %10000000,
    %10011111,

    %10001110, // CGRAM character 6
    %10010001,
    %10010001,
    %10011111,
    %10010001,
    %10010001,
    %10000000,
    %10011111,

    %10010001, // CGRAM character 7
    %10011011,
    %10010101,
    %10010101,
    %10010001,
    %10010001,
    %10000000,
    %10011111,

    %10000000, // CGRAM character 8
    %10000100,
    %10001000,
    %10011110,
    %10001000,
    %10000100,
    %10000000,
    %10011111,

    %00000000  // End of table marker
)

Inline Sub Nop()
    Asm
        Nop
    End Asm
End Sub

Sub LCD_E_Pulse()
    E_PIN = 1
    WREG = PORTC
    Nop()
    Nop()
    Nop()
    Nop()
    Nop()
    Nop()
    Nop()
//    delayus(4)
    E_PIN = 0
//    delayus(4)
    WREG = PORTC
    Nop()
    Nop()
    Nop()
    Nop()
    Nop()
    Nop()
    Nop()
End Sub

Sub LCD_DelayPOR()
    DelayMS(15)
End Sub

Sub LCD_Delay()
    DelayMS(5)
End Sub

Function LCD_GetByte() As Byte
    Dim LCD_Data As Byte

    LCD_PORT_DIR = LCD_PORT_DIR Or LCD_DATA_BITS // make LCD data bits inputs
    RW_PIN = 1

    E_PIN = 1
    DelayUS(4)
    LCD_Data = LCD_PORT_IN And LCD_DATA_BITS
    E_PIN = 0
    DelayUS(4)

    LCD_Data = (LCD_Data >> 4) Or (LCD_Data << 4)

    E_PIN = 1
    DelayUS(4)
    LCD_Data = LCD_Data Or (LCD_PORT_IN And LCD_DATA_BITS)
    E_PIN = 0
    DelayUS(4)

  #if defined(LCD_DATA_ON_HIGH_4_BITS)
    LCD_Data = (LCD_Data >> 4) Or (LCD_Data << 4)
  #endif
    result = LCD_Data
End Function

Sub LCD_PutByte(LCD_Data As Byte)
    LCD_PORT_DIR = LCD_PORT_DIR And Not LCD_DATA_BITS // make LCD data bits outputs
    RW_PIN = 0

    // send first nibble
    LCD_PORT_OUT = LCD_PORT_OUT And Not LCD_DATA_BITS
  #if Not defined (LCD_DATA_ON_HIGH_4_BITS)
    LCD_Data = (LCD_Data >> 4) Or (LCD_Data << 4)
  #endif
    LCD_PORT_OUT = LCD_PORT_OUT Or (LCD_Data And LCD_DATA_BITS)
    LCD_E_Pulse()

    LCD_Data = (LCD_Data >> 4) Or (LCD_Data << 4)
    LCD_PORT_OUT = LCD_PORT_OUT And Not LCD_DATA_BITS
    LCD_PORT_OUT = LCD_PORT_OUT Or (LCD_Data And LCD_DATA_BITS)
    LCD_E_Pulse()

    LCD_PORT_DIR = LCD_PORT_DIR Or LCD_DATA_BITS // make LCD data bits inputs
End Sub

Sub LCD_Busy()
    Dim LCD_Data As Byte

    If (LCD_BusyBit <> 0) Then
        LCD_PORT_DIR = LCD_PORT_DIR Or LCD_DATA_BITS // make LCD data bits inputs
        LCD_Data = 0

        RS_PIN = 0
        RW_PIN = 1
        Repeat
            LCD_Data = LCD_GetByte()
        Until ((LCD_Data And LCD_BusyBit) = 0)
    Else
        LCD_Delay() // use 5ms delay when busy bit is unknown
    EndIf
End Sub


Public Sub LCD_SetCGRamAddr(data As Byte)
    LCD_Busy()
    RS_PIN = 0
    LCD_PutByte(data Or $40)
End Sub

Public Sub LCD_SetDDRamAddr(data As Byte)
    LCD_Busy()
    RS_PIN = 0
    LCD_PutByte(data Or $80)
End Sub

Public Sub LCD_WriteCmd(data As Byte)
    LCD_Busy()
    RS_PIN = 0
    LCD_PutByte(data)
End Sub

Public Sub LCD_WriteData(data As Byte)
    LCD_Busy()
    RS_PIN = 1
    LCD_PutByte(data)
    RS_PIN = 0
End Sub

//void LCD_WriteConstString(const unsigned char * prString)
Inline Function TBLRD_() As TABLAT
    Asm
        TBLRD*
    End Asm
End Function

Inline Function TBLRD_POSTINC() As TABLAT
    Asm
        TBLRD*+
    End Asm
End Function

Public Sub LCD_WriteConstString(prString As TABLEPTR)
    While (TBLRD_() <> 0)
        LCD_WriteData(TBLRD_POSTINC())
    End While
End Sub

Public Sub LCD_WriteString(pString As String)
    Dim ix As Byte

    ix = 0
    While (Byte(pString(ix)) <> 0)
        LCD_WriteData(Byte(pString(ix)))
        ix = ix + 1
    End While
End Sub

Public Sub LCD_Init()
    Dim LCD_Data As Byte

    LCD_BusyBit = 0
    LCD_PORT_DIR = LCD_PORT_DIR  And Not LCD_DATA_BITS // make LCD data bits outputs
    E_PIN_DIR = 0                  // make LCD Enable strobe an output
    RW_PIN_DIR = 0                 // make LCD Read/Write select an output
    RS_PIN_DIR = 0                 // make LCD Register select an output
  #if defined(LCD_POWER_EN_DIR)
    LCD_POWER_EN_DIR = 0           // make LCD Power enable an output
  #endif
    E_PIN = 0                      // set LCD Enable strobe to not active
    RW_PIN = 0                     // set LCD Read/Write select to Write
    RS_PIN = 0                     // set LCD Register select to command group
    LCD_PORT_OUT = LCD_PORT_OUT  And Not LCD_DATA_BITS // set LCD data bits to zero
  #if defined(LCD_POWER_EN)
    LCD_POWER_EN = 1               // Turn on LCD power
  #endif
    LCD_DelayPOR()                 // wait for LCD power on to complete

    // Force LCD to 8-bit mode
    LCD_PORT_OUT = LCD_PORT_OUT And Not LCD_DATA_BITS // set LCD data bits to zero
    LCD_PORT_OUT = LCD_PORT_OUT Or (%00110011 And LCD_DATA_BITS)
    LCD_E_Pulse()
    LCD_Delay()
    LCD_E_Pulse()
    LCD_Delay()
    LCD_E_Pulse()
    LCD_Delay()

    // Set LCD to 4-bit mode
    LCD_PORT_OUT = LCD_PORT_OUT And Not LCD_DATA_BITS // set LCD data bits to zero
    LCD_PORT_OUT = LCD_PORT_OUT Or (%00100010 And LCD_DATA_BITS)
    LCD_E_Pulse()
    LCD_Delay()

    // Initialize LCD mode
    LCD_WriteCmd(LCD_FORMAT)

    //
    // Find position of busy bit
    // Required when using 4-bit mode
    //
    LCD_SetDDRamAddr(LINE_ONE+1)
    LCD_Busy()
    RS_PIN = 0
    LCD_Data = LCD_GetByte()

    If (LCD_Data = $01) Then
        LCD_BusyBit = $80
    ElseIf (LCD_Data = $10) Then
        LCD_BusyBit = $08
    Else
        LCD_BusyBit = $00
    EndIf

    // Turn on display, Setup cursor and blinking
    LCD_WriteCmd(DOFF And CURSOR_OFF And BLINK_OFF)
    LCD_WriteCmd(DON And CURSOR_OFF And BLINK_OFF)
    LCD_WriteCmd(CLEAR_DISPLAY)
    LCD_WriteCmd(SHIFT_CUR_LEFT)

    // Initialize the character generator RAM
    LCD_SetCGRamAddr(0)
    LCD_WriteConstString(@(CGRAM_Table))

    // Set first position on line one, left most character
    LCD_SetDDRamAddr(LINE_ONE)
End Sub

End Module
