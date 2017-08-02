/*
 * File:     main.c
 * Target:   PIC16F690
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.65
 *
 *                         PIC16F690
 *                 +----------:_:----------+
 *       PWR ->  1 : VDD               VSS : 20 <- GND
 *           <>  2 : RA5/T1CKI     PGD/RA0 : 19 <> PGD
 *       U/D <>  3 : RA4           PGC/RA1 : 18 <> PGC
 *       VPP ->  4 : RA3/VPP     T0CKI/RA2 : 17 <> 
 *   LCD_R/W <>  5 : RC5               RC0 : 16 <> LCD_D4  
 *    LCD_RS <>  6 : RC4               RC1 : 15 <> LCD_D5  
 *    LCD_D7 <>  7 : RC3               RC2 : 14 <> LCD_D6  
 *           <>  8 : RC6               RB4 : 13 <> LCD_E
 *       CSn <>  9 : RC7           RXD/RB5 : 12 <> RXD
 *       TXD <> 10 : RB7/TXD           RB6 : 11 <> 
 *                 +-----------------------:
 *                          DIP-20
 *
 */

#include <stdlib.h>
#include "init.h"
#include "lcd.h"
#include "buttons.h"
/*
 * Global Data 
 */
unsigned char gButtonEvent;
/*
 * Initialize TIMER0
 * 
 * TIMER0 needs to assert an interrupt every 1.024 milliseconds.
 */
void TIMER0_Init( void )
{
    INTCONbits.T0IE = 0;        /* disable TIMER0 interrupts */
    OPTION_REG |= 0b00101111;   /* set TIMER0 clock source and prescale select to default state */
    OPTION_REG &= 0b11010010;   /* Clock source FOSC/4, TIMER0 has prescaler, prescale is 1:8 */
    TMR0 = 0;                   /* start count from zero */
    INTCONbits.T0IF = 0;        /* clear interrupt request */
    INTCONbits.T0IE = 1;        /* enable TIMER0 interrupt source */
}
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
 * Display application name and version
 */
void ShowLCDSymbols(unsigned char Symbol)
{
    unsigned char buffer[17];
    unsigned char count;
    
    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteConstString("Symbols:        ");
    LCD_SetDDRamAddr(LINE_ONE+9);
    buffer[0] = 0;
    utoa(buffer,Symbol,10);
    LCD_WriteString(buffer);
    LCD_WriteData('-');

    buffer[0] = 0;
    utoa(buffer,Symbol+15U,10);
    LCD_WriteString(buffer);

    LCD_SetDDRamAddr(LINE_TWO);
    for(count = 0; count < 16; count++)
    {
        LCD_WriteData(Symbol++);
    }
}
/*
 * Main program
 */
void main(void) {
    
    unsigned char ButtonState;
    unsigned char LCD_symbols;
    
    PIC_Init();
    LCD_Init();
    TIMER0_Init();
    Buttons_Init();
    gButtonEvent = 0;
    INTCONbits.GIE = 1;
    LCD_symbols = 0;

    /* Display the application name and version information */
    ShowVersion();
    /* Show what is in the character generator RAM */
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteConstString("\010\011\012\013\014\015\016\017"); /* octal byte constants in a string */
    LCD_WriteConstString(" 17AUG02");

    /*
     * Application loop
     */
    for(;;)
    {
        if (gButtonEvent)
        {
            gButtonEvent = 0;
            
            ButtonState = Buttons_GetStatus();
            if( ButtonState & BUTTON_S2_CHANGE_MASK)
            { /* if S2 changed */
                if ( ButtonState & BUTTON_S2_STATE_MASK )
                { /* is S2 changed to pressed */
                    ShowLCDSymbols(LCD_symbols);
                    LCD_symbols += 16;
                }
            }
        }
    }
}
/*
 * Interrupt handlers
 */
void interrupt ISR_Handler(void)
{
    /* Handle system tick */
    if (INTCONbits.T0IE)
    {
        if(INTCONbits.T0IF)
        {
            INTCONbits.T0IF = 0;
            if (Buttons_Poll() & (BUTTON_S2_CHANGE_MASK | BUTTON_S3_CHANGE_MASK))
            {
                if(!gButtonEvent)
                {
                    gButtonEvent = 1;
                }
            }
        }
    }
}
