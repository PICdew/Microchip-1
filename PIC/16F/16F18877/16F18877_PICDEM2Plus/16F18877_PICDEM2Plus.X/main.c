/*
 * File:     main.c
 * Target:   PIC16F18877
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.61
 *
 *                         PIC16F18877
 *                 +----------:_:----------+
 *   S1  VPP ->  1 : RE3/MCLR/VPP  PGD/RB7 : 40 <> PGD
 * R16(0-5V) ->  2 : RA0/AN0       PGC/RB6 : 39 <> PGC
 *           <>  3 : RA1               RB5 : 38 <>
 *           <>  4 : RA2               RB4 : 37 <>
 *           <>  5 : RA3               RB3 : 36 <> LED_D5
 *   S2      ->  6 : RA4               RB2 : 35 <> LED_D4
 *   S3      ->  7 : RA5               RB1 : 34 <> LED_D3
 *           <>  8 : RE0               RB0 : 33 <> LED_D2
 *           <>  9 : RE1               VDD : 32 <- PWR
 *           <> 10 : RE2               VSS : 31 <- GND
 *       PWR -> 11 : VDD               RD7 : 30 -> LCD_ON
 *       GND -> 12 : VSS               RD6 : 29 -> LCD_E
 *      4MHZ -> 13 : RA7/OSC1          RD5 : 28 -> LCD_RW
 *           <- 14 : RA6/OSC2          RD4 : 27 -> LCD_RS
 *           <> 15 : RC0/SOSCO   RX/DT/RC7 : 26 <- RXD
 *           <> 16 : RC1/SOSCI   TX/CK/RC6 : 25 -> TXD
 *    BUZZER <> 17 : RC2/CCP1          RC5 : 24 <>
 *       SCL <> 18 : RC3/SCL       SDA/RC4 : 23 <> SDA
 *    LCD_D4 <> 19 : RD0               RD3 : 22 <> LCD_D7
 *    LCD_D5 <> 20 : RD1               RD2 : 21 <> LCD_D6
 *                 +-----------------------:
 *                          DIP-40
 *
 *   PICDEM 2 Plus:
 *   RD0 <> LCD_D4    Special note that the LCD module on my PICDEM2 PLUS
 *   RD1 <> LCD_D5    is a NOVATEK 7605. In 4-bit mode the NOVATEK 7605 is
 *   RD2 <> LCD_D6    not 100% compatible with the Hitachi HD44780. The
 *   RD3 <> LCD_D7    issue is that in 4-bit mode a status read returns the
 *   RD4 -> LCD_RS    4-bits in an order that is different from the HD44780.
 *   RD5 -> LCD_R/W
 *   RD6 -> LCD_E
 *   RD7 -> LCD_ON
 *
 * WARNING:
 *   This code runs on a modified PICDEM 2 Plus demo board.
 *   The connection for push button S3 has been from RB0 to RA5.
 *
 *
 */

#include <stdlib.h>
#include "init.h"
#include "lcd.h"

/*
 * Display application name and version
 */
void ShowVersion(void)
{
    unsigned char buffer[17];
    
    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteConstString("LCD Test ");

    buffer[0] = 0;
    utoa(buffer,MAJOR_REV,10);
    LCD_WriteString(buffer);
    LCD_WriteData('.');

    buffer[0] = 0;
    utoa(buffer,MINOR_REV,10);
    LCD_WriteString(buffer);
    LCD_WriteData('.');

    buffer[0] = 0;
    utoa(buffer,LCD_GetBusyBitMask(),10);
    LCD_WriteString(buffer);
}
/*
 * Main program
 */
void main(void) {
    
    Init_PIC();
    LCD_Init();

    /* Display the application name and version information */
    ShowVersion();
    /* Show what is in the character generator RAM */
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteConstString("\010\011\012\013\014\015\016\017"); /* octal byte constants in a string */
    LCD_WriteConstString(" 17JUN05");

    /*
     * Application loop
     */
    for(;;)
    {
        
    }
}
