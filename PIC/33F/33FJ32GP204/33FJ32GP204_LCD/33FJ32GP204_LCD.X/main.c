/*
 * File: main.c
 * Target: dsPIC33FJ32GP204
 * IDE: MPLABX v4.05
 * Compiler: XC16 v1.35
 * Target hardware: Unknown
 *
 * Description:
 *  Example of sending characters to a 16 character by 2 row LCD module using the HD44780 4-bit interface method.
 *
 * Notes:
 *
 *                                                 dsPIC33FJ32GP204
 *              +-----------+              +-----------+                   +-----------+                +-----------+
 * LCD_RW <>  1 : RB9/SDA1  :        <> 12 : RA10      :             <> 23 : RB2       :          <> 34 : RA4/SOSCO :
 *        <>  2 : RC6       :        <> 13 : RA7       :             <> 24 : RB3       :          <> 35 : RA9       :
 *        <>  3 : RC7       :        <> 14 : RB14      :             <> 25 : RC0       :          <> 36 : RC3       :
 *        <>  4 : RC8       :        <> 15 : RB15      :             <> 26 : RC1       :          <> 37 : RC4       :
 *        <>  5 : RC9       :    GND -> 16 : AVSS      :             <> 27 : RC2       :          <> 38 : RC5       :
 *    GND <>  6 : VSS       :    3v3 -> 17 : AVDD      :         3v3 -> 28 : VDD       :      GND -> 39 : VSS       :
 *   10uF <>  7 : VCAP      :    VPP -> 18 : MCLRn     :         GND -> 29 : VSS       :      3v3 -> 40 : VDD       :
 * LCD_RS <>  8 : RB10/PGED2:        <> 19 : RA0       :        OSCI <> 30 : RA2/OSCI  :   LCD_D5 <> 41 : RB5/PGED3 :
 *        <>  9 : RB11/PGEC2:        <> 20 : RA1       :        OSCO <> 31 : RA3/OSCO  :   LCD_D6 <> 42 : RB6/PGEC3 :
 *        <> 10 : RB12      :    PGD <> 21 : RB0/PGED1 :             <> 32 : RA8       :   LCD_D7 <> 43 : RB7/INT0  :
 *        <> 11 : RB13      :    PGC <> 22 : RB1/PGEC1 :      LCD_D4 <> 33 : RB4/SOSCI :   LCD_E  <> 44 : RB8/SCL1  :
 *              +-----------+              +-----------+                   +-----------+                +-----------+
 *                                                     TQFP-44
 *
 */
#include "init.h"
#include "lcd.h"

const char mesg1[] = "HARDWARE        ";
const char mesg2[] = "PERI            ";

int main(void) 
{
    PIC_Init();
    LCD_Init();
    
    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteConstString(mesg1);
    
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteConstString(mesg2);
    
    TRISCbits.TRISC6 = 0;
    
    for(;;)
    {
        LATCbits.LATC6 = 1;
        __delay_ms(100);
        LATCbits.LATC6 = 0;
        __delay_ms(100);
    }
    
    return 0;
}
