/*
 * File:   main.c
 * Author: 
 *
 * Target: PIC18F24K20, PIC18F2520
 *
 * Description:
 *  
 *  See:  https://www.electro-tech-online.com/threads/reading-a-4x4-switch-matrix.153166/
 *
 *
 */

#include <xc.h>
#include <stddef.h>
#include "main.h"
#include "init.h"
#include "keypad.h"
#include "lcd.h"
#include "tick.h"

#define DISPLAY_UPDATE_PERIOD (147)

volatile unsigned char gScanKeypadFlag;

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
            if(gScanKeypadFlag == 0) gScanKeypadFlag = 1;
        }
    }
}
/*
 * Display application name and version
 */
void ShowVersion(void)
{
    unsigned char buffer[17] = "\010\011\012\013\014\015\016\017"; /* octal byte constants in a string */
    
    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteConstString("Test: LCD+Keypad");
    /* Show what is in the character generator RAM */
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteString(buffer); 
    LCD_WriteConstString(" 18MAR10");
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
    LCD_Init();
    Keypad_Init();
    Tick_Init();

    INTCONbits.PEIE = 1;
    INTCONbits.GIE  = 1;

    /* Display the application name and version information */
    ShowVersion();

    KP_sample = Keypad_GetSample();

    for(;;)
    {
        if(gScanKeypadFlag != 0)
        {
            gScanKeypadFlag = 0;
            Keypad_Scan();
        }
        /* check for and process key presses */
        if (Keypad_GetEvent() == eKeyChanged)
        {
            LCD_SetDDRamAddr(LINE_TWO);
            LCD_WriteConstString("Key Pressed:    ");
            Key = Keypad_GetKey(NULL);
            if (Key != 0)
            {
                LCD_SetDDRamAddr(LINE_TWO+13);
                LCD_WriteData(Key);
                switch (Key)
                {
                    case '0':
                    case '1':
                    case '2':
                    case '3':
                    case '4':
                    case '5':
                    case '6':
                    case '7':
                    case '8':
                    case '9':
                        break;
                    case 'E':
                        break;
                    case '.':
                        break;
                    case 'U':
                        break;
                    case 'D':
                        break;
                    case 'L':
                        break;
                    case 'R':
                        break;
                    default:
                        break;
                }
            }
        }
    }
}
