/*
 * File:     main.c
 * Author:   dan1138
 * Target:   PIC18F27K42
 * Compiler: XC8 v1.45
 * IDE:      MPLABX v4.05
 *
 * Created on July 21, 2018, 10:47 AM
 * 
 *                           PIC18F27K42
 *                 +------------:_:------------+
 *   ICD_VPP ->  1 : RE3/MCLR/VPP      PGD/RB7 : 28 <> ICD_PGD
 *    LCD_D4 <>  2 : RA0               PGC/RB6 : 27 <> ICD_PGC
 *    LCD_D5 <>  3 : RA1                   RB5 : 26 <> 
 *    LCD_D6 <>  4 : RA2                   RB4 : 25 <> 
 *    LCD_D7 <>  5 : RA3                   RB3 : 24 <> 
 *           <>  6 : RA4                   RB2 : 23 <> 
 *           <>  7 : RA5                   RB1 : 22 <> 
 *       GND <>  8 : VSS                   RB0 : 21 <> 
 *           <>  9 : RA7/OSC1              VDD : 20 <- 3v3
 *           <> 10 : RA6/OSC2              VSS : 19 <- GND
 *           <> 11 : RC0/SOSCO             RC7 : 18 <> LCD_E
 *           <> 12 : RC1/SOSCI             RC6 : 17 <> LCD_RW
 *           <> 13 : RC2                   RC5 : 16 <> LCD_RS
 *           <> 14 : RC3                   RC4 : 15 <> 
 *                 +---------------------------:
 *                            DIP-28
 *
 * Description:
 *  Interface HD44780 based LCD module with PIC18F27K42
 * 
 *  This project will set up the PIC controller to have only the PORT bit
 *  driving the GPIO pins in digital I/O mode. All function blocks are
 *  disabled including the ADC, Comparators, Timers etc.
 * 
 * Notes:
 *  Tested with the simulator but not in real hardware.
 */

#include <xc.h>
#include "init.h"
#include "lcd.h"

/*
 * Display application name and version
 */
void ShowVersion(void)
{
    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteConstString("PIC18LF27K42 1.0");
}

void main(void)
{
    /*
     * Power On Reset initialization
     */
    PIC_Init();
    LCD_Init();
    
    /* Display application and version */
    ShowVersion();
    /* Show what is in the character generator RAM */
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteConstString("\010\011\012\013\014\015\016\017"); /* octal byte constants in a string */
    LCD_WriteConstString(" 18JUL21");
    /*
     * Main application loop
     */
    for(;;)
    {
        
    }
}
