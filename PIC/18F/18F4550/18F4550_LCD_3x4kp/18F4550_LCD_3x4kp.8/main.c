/*
 * File:   main.c
 * Author: 
 *
 * Target: PIC18F4550
 *
 * Description:
 *  
 *  1 - MPPT (Maximum power point tracking) algorithm for a Photo-Voltaic system
 *  2 - Provide 2 PWM signals to my MOSFETs
 *  3 - Voltage and current sensor (2 to 3 each)
 *  4 - Two temprature sensors
 *  5 - Keypad 3x4, telephone (1-9,*,0,#)
 *  6 - LCD module, ASCII, 16 characters, 2 rows
 *
 *  See:  http://www.microchip.com/forums/FindPost/979462
 *
 *  Also: http://www.microchip.com/forums/FindPost/978149
 *        http://www.microchip.com/forums/FindPost/978369
 *        http://www.microchip.com/forums/FindPost/979382
 *        http://www.microchip.com/forums/FindPost/981970
 *        http://www.microchip.com/forums/FindPost/982425
 *
 */

#include <xc.h>
#include <stdlib.h>
#include "main.h"
#include "init.h"
#include "adc.h"
#include "keypad.h"
#include "lcd.h"
#include "tick.h"

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
            Keypad_Scan();
        }
    }
}
/*
 * Display application name and version
 */
void ShowVersion(unsigned int MajorVersion, unsigned int MinorVersion)
{
    unsigned char buffer[17];
    
    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteConstString("LCD Test ");

    buffer[0] = 0;
    utoa(buffer,MajorVersion,10);
    LCD_WriteString(buffer);
    LCD_WriteData('.');

    buffer[0] = 0;
    utoa(buffer,MinorVersion,10);
    LCD_WriteString(buffer);
}
/*
 * Used for keypad code debug
 */
void ShowKeypadMatrix(unsigned int Sample)
{
    unsigned char buffer[17];
    
    LCD_SetDDRamAddr(LINE_ONE);
    buffer[0] = 0;
    utoa(buffer,Sample | 0xF000,2);
    buffer[0] = '1';
    buffer[1] = '=';
    buffer[2] = 'P';
    buffer[3] = ':';
    LCD_WriteString(buffer);
}
/*
 * Used for ADC code debug
 */
void ShowAdcChannel(unsigned char Key)
{
    unsigned char buffer[17];

    if ((Key >= '0') && (Key <= '7'))
    {
        LCD_SetDDRamAddr(LINE_ONE);
        LCD_WriteConstString("                ");
        LCD_SetDDRamAddr(LINE_ONE);
        LCD_WriteData('A');
        LCD_WriteData('N');
        LCD_WriteData(Key);
        LCD_WriteData(':');
        buffer[0] = 0;
        utoa(buffer,ADC_ReadChannel(Key & 0x0F),10);
        LCD_WriteString(buffer);
    }
}
/*
 * Application
 */
void main(void) 
{
    unsigned int  KP_sample;
    unsigned char Key;
    KeypadEvent_t Keypad_Event;
    
    PIC_Init();
    ADC_Init();
    LCD_Init();
    Keypad_Init();
    Tick_Init();
    ADC_ReadChannel(0);

    INTCONbits.PEIE = 1;
    INTCONbits.GIE  = 1;

    /* Display the application name and version information */
    ShowVersion(1,3);

    /* Show what is in the character generator RAM */
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteConstString("\010\011\012\013\014\015\016\017"); /* octal byte constants in a string */
    
    KP_sample = Keypad_GetSample();

    for(;;)
    {
        /* check for and process key presses */
        switch (Keypad_GetEvent())
        {
            case eKeyChanged:
            {
                LCD_SetDDRamAddr(LINE_TWO);
                LCD_WriteConstString("Key Pressed:    ");
                Key = Keypad_GetKey(&Keypad_Event);
                
                if (Key)
                {
                    ShowAdcChannel(Key);
                    LCD_SetDDRamAddr(LINE_TWO+13);
                    LCD_WriteData(Key);
                }
                break;
            }
            default:
            {
                break;
            }
        }
    }
}
