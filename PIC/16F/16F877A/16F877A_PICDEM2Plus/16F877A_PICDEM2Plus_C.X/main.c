/*
 * File:     main.c
 * Target:   PIC16F877A
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.61
 *
 *                         PIC16F877A
 *                 +----------:_:----------+
 *   S1  VPP ->  1 : MCLR/VPP      PGD/RB7 : 40 <> PGD
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
 *   The connection for push button S3 has been moved from RB0 to RA5.
 *
 *
 */

#include <stdlib.h>
#include "init.h"
#include "lcd.h"
#include "buttons.h"
#include "usart.h"
#include "utility.h"
/*
 * Global Data 
 */
unsigned char gButtonEvent;
/*
 * Initialize TIMER0
 */
void TIMER0_Init( void )
{
    INTCONbits.TMR0IE = 0;       /* disable TIMER0 interrupts */
    TMR0 = 0;                    /* start count from zero */
    INTCONbits.TMR0IF = 0;       /* clear interrupt request */
    INTCONbits.TMR0IE = 1;       /* enable TIMER0 interrupt source */
}
/*
 * Display application name and version
 */
void ShowVersion(void)
{
    unsigned char buffer[17];
    
    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteConstString(APP_MESSAGE);
    USART_WriteConstString(APP_MESSAGE);

    buffer[0] = 0;
    BinToDecASCII(buffer,MAJOR_REV);
    LCD_WriteString(buffer);
    LCD_WriteData('.');
    USART_WriteString(buffer);
    USART_Write('.');

    buffer[0] = 0;
    BinToDecASCII(buffer,MINOR_REV);
    LCD_WriteString(buffer);
    LCD_WriteData('.');
    USART_WriteString(buffer);
    USART_Write('.');

    buffer[0] = 0;
    BinToDecASCII(buffer,LCD_GetBusyBitMask());
    LCD_WriteString(buffer);
    USART_WriteString(buffer);
    USART_WriteConstString("\r\n");
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
    BinToDecASCII(buffer,Symbol);
    LCD_WriteString(buffer);
    LCD_WriteData('-');

    buffer[0] = 0;
    BinToDecASCII(buffer,Symbol+15U);
    LCD_WriteString(buffer);

    LCD_SetDDRamAddr(LINE_TWO);
    for(count = 0; count < 16; count++)
    {
        LCD_WriteData(Symbol++);
    }
}
/*
 *
 */
void DoNextState_LCD(void) 
{
    static unsigned char LCD_symbols = 0;
    ShowLCDSymbols(LCD_symbols);
    LCD_symbols += 16;
}
/*
 *
 */
void DoNextState_LED(void) 
{
    PORTB = (PORTB & 0xF0U) | ((PORTB + 1U) & 0x0FU);
}
/*
 * Main program
 */
void main(void) {
    
    unsigned char ButtonState;
    unsigned char USART_Data;
    
    PIC_Init();
    LCD_Init();
    TIMER0_Init();
    USART_Init(USART_BAUD_9600, USART_READ_AND_WRITE, USART_ASYNC, USART_9TH_BIT_OFF);
    Buttons_Init();
    gButtonEvent = 0;
    INTCONbits.GIE = 1;

    /* Display the application name and version information */
    ShowVersion();
    /* Show what is in the character generator RAM */
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteConstString("\010\011\012\013\014\015\016\017"); /* octal byte constants in a string */
    LCD_WriteConstString(" 17SEP28");

    TRISB &= 0xF0;      /* make PORTB bits 0-3 outputs */
    PORTB &= 0xF0;      /* turn off LEDs on PORTB bits 0-3 */

    USART_WriteConstString("Type the character 1 to show next group of symbols on the LCD.\r\n");    
    USART_WriteConstString("Type the character 2 to increment the LED pattern.\r\n");    
    /*
     * Application loop
     */
    for(;;)
    {
        if(USART_Data_Ready())
        {
            USART_Read(&USART_Data);

            /* call stack goes too deep to allow interrupts */
            INTCONbits.GIE = 0;
            switch (USART_Data)
            {
                case '1':
                    DoNextState_LCD();
                    break;

                case '2':   
                    DoNextState_LED();
                    break;
                default:
                    break;
            }
            INTCONbits.GIE = 1;
        }

        if (gButtonEvent)
        {
            /* call stack goes too deep to allow interrupts */
            INTCONbits.GIE = 0;
            gButtonEvent = 0;
            
            ButtonState = Buttons_GetStatus();
            if( ButtonState & BUTTON_S2_CHANGE_MASK)
            { /* if S2 changed */
                if ( ButtonState & BUTTON_S2_STATE_MASK )
                { /* is S2 changed to pressed */
                    DoNextState_LCD();
                }
            }
            if( ButtonState & BUTTON_S3_CHANGE_MASK)
            { /* if S3 changed */
                if ( ButtonState & BUTTON_S3_STATE_MASK )
                { /* is S3 changed to pressed */
                    DoNextState_LED();
                }
            }
            INTCONbits.GIE = 1;
        }
    }
}
/*
 * Interrupt handlers
 */
void interrupt ISR_Handler(void)
{
    /* Handle system tick */
    if (INTCONbits.TMR0IE)
    {
        if(INTCONbits.TMR0IF)
        {
            INTCONbits.TMR0IF = 0;
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
