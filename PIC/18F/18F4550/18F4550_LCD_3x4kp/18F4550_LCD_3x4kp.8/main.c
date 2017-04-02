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
 *  5 - Keypad 3x4, telephone style (1-9,*,0,#)
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
#include "pwm.h"

#define MAJOR_REV (1)
#define MINOR_REV (5)
#define DISPLAY_UPDATE_PERIOD (147)

volatile unsigned char SysTick;

#define PWM_TestDelta (7)
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
            SysTick++;
            Keypad_Scan();
        }
    }
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
void ShowAdcChannel(unsigned char Channel)
{
    unsigned char buffer[17];

    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteConstString("                ");
    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteData('A');
    LCD_WriteData('N');
    LCD_WriteData(Channel+'0');
    LCD_WriteData(':');
    buffer[0] = 0;
    utoa(buffer,ADC_ReadChannel(Channel),10);
    LCD_WriteString(buffer);
}
/*
 * Used for PWM code debug
 */
void ShowPwmDutyCycle(unsigned char PWM, unsigned char DutyCycle)
{
    unsigned char buffer[17];

    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteConstString("CCP :           ");
    LCD_SetDDRamAddr(LINE_ONE+3);
    LCD_WriteData(PWM+'0');
    LCD_SetDDRamAddr(LINE_ONE+5);
    buffer[0] = 0;
    utoa(buffer,DutyCycle,10);
    LCD_WriteString(buffer);
    LCD_WriteData('%');
}
/*
 * Application
 */
void main(void) 
{
    unsigned int  KP_sample;
    unsigned char Key;
    KeypadEvent_t Keypad_Event;
    unsigned char PWM1_DutyCycle;
    unsigned char PWM2_DutyCycle;
    unsigned char DisplayUpdateTick;
    unsigned char DisplayUpdateFlag;
    
    PIC_Init();
    ADC_Init();
    LCD_Init();
    Keypad_Init();
    Tick_Init();
    PWM_Init();

    INTCONbits.PEIE = 1;
    INTCONbits.GIE  = 1;

    PWM1_DutyCycle = 40;
    PWM2_DutyCycle = 60;

    /* Display the application name and version information */
    ShowVersion();

    PWM_SetPwm1DutyCycle(PWM1_DutyCycle);
    PWM_SetPwm2DutyCycle(PWM2_DutyCycle);

    /* Show what is in the character generator RAM */
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteConstString("\010\011\012\013\014\015\016\017"); /* octal byte constants in a string */
    LCD_WriteConstString(" 17APR01");
    
    KP_sample = Keypad_GetSample();

    DisplayUpdateFlag = 0;

    for(;;)
    {
        /* Update ADC disply every DISPLAY_UPDATE_PERIOD ticks */
        if ((DisplayUpdateFlag != 0) && ((unsigned char)(SysTick - DisplayUpdateTick) >= DISPLAY_UPDATE_PERIOD))
        {
            DisplayUpdateTick = SysTick;
            ShowAdcChannel(DisplayUpdateFlag & 0x0F);
        }

        /* check for and process key presses */
        if (Keypad_GetEvent() == eKeyChanged)
        {
            LCD_SetDDRamAddr(LINE_TWO);
            LCD_WriteConstString("Key Pressed:    ");
            Key = Keypad_GetKey(&Keypad_Event);
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
                        DisplayUpdateFlag = Key;
                        DisplayUpdateTick = SysTick;
                        ShowAdcChannel(DisplayUpdateFlag & 0x0F);
                        break;
                    case '8':
                        if (PWM1_DutyCycle >= PWM_TestDelta) PWM1_DutyCycle -= PWM_TestDelta;
                        else PWM1_DutyCycle = 0;
                        PWM_SetPwm1DutyCycle(PWM1_DutyCycle);
                        ShowPwmDutyCycle(1,PWM1_DutyCycle);
                        DisplayUpdateFlag = 0;
                        break;
                    case '9':
                        if (PWM1_DutyCycle <= 100-PWM_TestDelta) PWM1_DutyCycle += PWM_TestDelta;
                        else PWM1_DutyCycle = 100;
                        PWM_SetPwm1DutyCycle(PWM1_DutyCycle);
                        ShowPwmDutyCycle(1,PWM1_DutyCycle);
                        DisplayUpdateFlag = 0;
                        break;
                    case '*':
                        if (PWM2_DutyCycle >= PWM_TestDelta) PWM2_DutyCycle -= PWM_TestDelta;
                        else PWM2_DutyCycle = 0;
                        PWM_SetPwm2DutyCycle(PWM2_DutyCycle);
                        ShowPwmDutyCycle(2,PWM2_DutyCycle);
                        DisplayUpdateFlag = 0;
                        break;
                    case '#':
                        if (PWM2_DutyCycle <= 100-PWM_TestDelta) PWM2_DutyCycle += PWM_TestDelta;
                        else PWM2_DutyCycle = 100;
                        PWM_SetPwm2DutyCycle(PWM2_DutyCycle);
                        ShowPwmDutyCycle(2,PWM2_DutyCycle);
                        DisplayUpdateFlag = 0;
                        break;
                    default:
                        break;
                }
            }
        }
    }
}
