//
// File:   lcd.c
// Author:
//
// Target: PIC18F24K20, PIC18F2520
//
module lcd

include "init_h.bas"
#define _LCD_DATA_BITS   = $F0
const LCD_DATA_BITS = _LCD_DATA_BITS

// Define the LCD port pins
public dim
    E_PIN               as LATA.bits(5),
    RW_PIN              as LATA.bits(4),
    RS_PIN              as LATA.bits(3),
    LCD_PORT_IN         as PORTC,
    LCD_PORT_OUT        as LATC

public dim
    E_PIN_DIR           as TRISA.bits(5),
    RW_PIN_DIR          as TRISA.bits(4),
    RS_PIN_DIR          as TRISA.bits(3),
    LCD_PORT_DIR        as TRISC

// Clear display command
public const CLEAR_DISPLAY = %00000001

// Return home command
public const RETURN_HOME = %00000010

// Display ON/OFF Control defines
public const DON         = %00001111    // Display on
public const DOFF        = %00001011    // Display off
public const CURSOR_ON   = %00001111    // Cursor on
public const CURSOR_OFF  = %00001101    // Cursor off
public const BLINK_ON    = %00001111    // Cursor Blink
public const BLINK_OFF   = %00001110    // Cursor No Blink

// Cursor or Display Shift defines
public const SHIFT_CUR_LEFT    = %00010011    // Cursor shifts to the left
public const SHIFT_CUR_RIGHT   = %00010111    // Cursor shifts to the right
public const SHIFT_DISP_LEFT   = %00011011    // Display shifts to the left
public const SHIFT_DISP_RIGHT  = %00011111    // Display shifts to the right

// Function Set defines
public const FOUR_BIT   = %00101111    // 4-bit Interface
public const EIGHT_BIT  = %00111111    // 8-bit Interface
public const LINE_5X7   = %00110011    // 5x7 characters, single line
public const LINE_5X10  = %00110111    // 5x10 characters
public const LINES_5X7  = %00111011    // 5x7 characters, multiple line

// Start address of each line
public const LINE_ONE    = $00
public const LINE_TWO    = $40

// Define the LCD interface and character size
public const LCD_FORMAT = FOUR_BIT and LINES_5X7

#if (_LCD_DATA_BITS = $0F)
  #define LCD_DATA_ON_LOW_4_BITS
#else
  #if (_LCD_DATA_BITS = $F0)
    #define LCD_DATA_ON_HIGH_4_BITS
  #else
    #error "LCD interface supports 4-bit mode only on high or low 4-bits of one port"
  #endif
#endif

dim LCD_BusyBit as byte

const CGRAM_Table() as byte =
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

inline sub Nop()
    asm
        NOP
    end asm
end sub

sub LCD_E_Pulse()
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
end sub

sub LCD_DelayPOR()
    delayms(15)
end sub

sub LCD_Delay()
    delayms(5)
end sub

function LCD_GetByte() as byte
    dim LCD_Data as byte

    LCD_PORT_DIR = LCD_PORT_DIR or LCD_DATA_BITS // make LCD data bits inputs
    RW_PIN = 1

    E_PIN = 1
    delayus(4)
    LCD_Data = LCD_PORT_IN and LCD_DATA_BITS
    E_PIN = 0
    delayus(4)

    LCD_Data = (LCD_Data >> 4) or (LCD_Data << 4)

    E_PIN = 1
    delayus(4)
    LCD_Data = LCD_Data or (LCD_PORT_IN and LCD_DATA_BITS)
    E_PIN = 0
    delayus(4)

  #if defined(LCD_DATA_ON_HIGH_4_BITS)
    LCD_Data = (LCD_Data >> 4) or (LCD_Data << 4)
  #endif
    result = LCD_Data
end function

sub LCD_PutByte(LCD_Data as byte)
    LCD_PORT_DIR = LCD_PORT_DIR and not LCD_DATA_BITS // make LCD data bits outputs
    RW_PIN = 0

    // send first nibble
    LCD_PORT_OUT = LCD_PORT_OUT and not LCD_DATA_BITS
  #if not defined (LCD_DATA_ON_HIGH_4_BITS)
    LCD_Data = (LCD_Data >> 4) or (LCD_Data << 4)
  #endif
    LCD_PORT_OUT = LCD_PORT_OUT or (LCD_Data and LCD_DATA_BITS)
    LCD_E_Pulse()

    LCD_Data = (LCD_Data >> 4) or (LCD_Data << 4)
    LCD_PORT_OUT = LCD_PORT_OUT and not LCD_DATA_BITS
    LCD_PORT_OUT = LCD_PORT_OUT or (LCD_Data and LCD_DATA_BITS)
    LCD_E_Pulse()

    LCD_PORT_DIR = LCD_PORT_DIR or LCD_DATA_BITS // make LCD data bits inputs
end sub

sub LCD_Busy()
    dim LCD_Data as byte

    if (LCD_BusyBit <> 0) then
        LCD_PORT_DIR = LCD_PORT_DIR or LCD_DATA_BITS // make LCD data bits inputs
        LCD_Data = 0

        RS_PIN = 0
        RW_PIN = 1
        repeat
            LCD_Data = LCD_GetByte()
        until ((LCD_Data and LCD_BusyBit) = 0)
    else
        LCD_Delay() // use 5ms delay when busy bit is unknown
    endif
end sub


public sub LCD_SetCGRamAddr(data as byte)
    LCD_Busy()
    RS_PIN = 0
    LCD_PutByte(data or $40)
end sub

public sub LCD_SetDDRamAddr(data as byte)
    LCD_Busy()
    RS_PIN = 0
    LCD_PutByte(data or $80)
end sub

public sub LCD_WriteCmd(data as byte)
    LCD_Busy()
    RS_PIN = 0
    LCD_PutByte(data)
end sub

public sub LCD_WriteData(data as byte)
    LCD_Busy()
    RS_PIN = 1
    LCD_PutByte(data)
    RS_PIN = 0
end sub

//void LCD_WriteConstString(const unsigned char * prString)
inline function TBLRD_() as TABLAT
    asm
        TBLRD*
    end asm
end function

inline function TBLRD_POSTINC() as TABLAT
    asm
        TBLRD*+
    end asm
end function

public sub LCD_WriteConstString(prString as TABLEPTR)
    while (TBLRD_() <> 0)
        LCD_WriteData(TBLRD_POSTINC())
    end while
end sub

public sub LCD_WriteString(pString as string)
    dim ix as byte

    ix = 0
    while (byte(pString(ix)) <> 0)
        LCD_WriteData(byte(pString(ix)))
        ix = ix + 1
    end while
end sub

public sub LCD_Init()
    dim LCD_Data as byte

    LCD_BusyBit = 0
    LCD_PORT_DIR = LCD_PORT_DIR  and not LCD_DATA_BITS // make LCD data bits outputs
    E_PIN_DIR = 0                  // make LCD Enable strobe an output
    RW_PIN_DIR = 0                 // make LCD Read/Write select an output
    RS_PIN_DIR = 0                 // make LCD Register select an output
  #if defined(LCD_POWER_EN_DIR)
    LCD_POWER_EN_DIR = 0           // make LCD Power enable an output
  #endif
    E_PIN = 0                      // set LCD Enable strobe to not active
    RW_PIN = 0                     // set LCD Read/Write select to Write
    RS_PIN = 0                     // set LCD Register select to command group
    LCD_PORT_OUT = LCD_PORT_OUT  and not LCD_DATA_BITS // set LCD data bits to zero
  #if defined(LCD_POWER_EN)
    LCD_POWER_EN = 1               // Turn on LCD power
  #endif
    LCD_DelayPOR()                 // wait for LCD power on to complete

    // Force LCD to 8-bit mode
    LCD_PORT_OUT = LCD_PORT_OUT and not LCD_DATA_BITS // set LCD data bits to zero
    LCD_PORT_OUT = LCD_PORT_OUT or (%00110011 and LCD_DATA_BITS)
    LCD_E_Pulse()
    LCD_Delay()
    LCD_E_Pulse()
    LCD_Delay()

    // Set LCD to 4-bit mode
    LCD_PORT_OUT = LCD_PORT_OUT and not LCD_DATA_BITS // set LCD data bits to zero
    LCD_PORT_OUT = LCD_PORT_OUT or (%00100010 and LCD_DATA_BITS)
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

    if (LCD_Data = $01) then
        LCD_BusyBit = $80
    elseif (LCD_Data = $10) then
        LCD_BusyBit = $08
    else
        LCD_BusyBit = $00
    endif

    // Turn on display, Setup cursor and blinking
    LCD_WriteCmd(DOFF and CURSOR_OFF and BLINK_OFF)
    LCD_WriteCmd(DON and CURSOR_OFF and BLINK_OFF)
    LCD_WriteCmd(CLEAR_DISPLAY)
    LCD_WriteCmd(SHIFT_CUR_LEFT)

    // Initialize the character generator RAM
    LCD_SetCGRamAddr(0)
    LCD_WriteConstString(@(CGRAM_Table))

    // Set first position on line one, left most character
    LCD_SetDDRamAddr(LINE_ONE)
end sub

end module
