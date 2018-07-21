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

#include "init.h"
#include "main.h"
#include "keypad.h"
#include "lcd.h"
#include "tick.h"

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
    LCD_WriteConstString(" 18MAR11");
}
/*
 * Application
 */
void main(void) 
{
    unsigned char Key;
    unsigned char KeyPressedMessageFlag;
    eKeyEvent_t KP_Event;
    
    PIC_Init();
    LCD_Init();
    Keypad_Init();
    Tick_Init();

    INTCONbits.PEIE = 1;
    INTCONbits.GIE  = 1;

    /* Display the application name and version information */
    ShowVersion();
    KeyPressedMessageFlag = 0;
    
    for(;;)
    {
        /* Scan the kepad matrix about every 2 milliseconds */
        if(gScanKeypadFlag != 0)
        {
            gScanKeypadFlag = 0;
            Keypad_Scan();
KP_Event = Keypad_GetEvent();
Nop();
Nop();
Nop();
        }
        /* check for and process key presses */
        if (KP_Event == eKeyChanged)
        {
            if (KeyPressedMessageFlag == 0)
            {
                KeyPressedMessageFlag = 1;
                LCD_SetDDRamAddr(LINE_TWO);
                LCD_WriteConstString("Key Pressed:    ");
            }

            Key = Keypad_GetKey(NULL);
Nop();
Nop();
Nop();
            if (Key != 0)
            {
                LCD_SetDDRamAddr(LINE_TWO+13);
Nop();
Nop();
Nop();
                LCD_WriteData(Key);
Nop();
Nop();
Nop();
                switch (Key)
                {
                    case '0':
                        break;
                    case '1':
                        break;
                    case '2':
                        break;
                    case '3':
                        break;
                    case '4':
                        break;
                    case '5':
                        break;
                    case '6':
                        break;
                    case '7':
                        break;
                    case '8':
                        break;
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
            else
            {
                LCD_SetDDRamAddr(LINE_TWO+13);
                LCD_WriteData(' ');
            }
        }
    }
}
