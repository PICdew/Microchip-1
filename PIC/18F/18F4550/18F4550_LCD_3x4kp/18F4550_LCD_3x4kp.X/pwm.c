/*
 * File:   pwm.c
 * Author: 
 *
 * Target: PIC18F4550
 */

#include <xc.h>
#include "init.h"
#include "pwm.h"

#define PWM_PERIOD (FCYC/50000UL)
/*
 * Setup PWM outputs for CCP1 and CCP2
 *
 * Use TIMER2 to make the PWM perior 50KHz
 * Start PWM outputs at 0% duty cycle
 */
void PWM_Init(void)
{
    PIE1bits.TMR2IE = 0;    /* Turn off interrupt sources */
    PIE1bits.CCP1IE = 0;
    PIE2bits.CCP2IE = 0;
    
    T2CON = 0;              /* Stop TIMER2 */
    CCP1CON = 0;            /* Stop PWM1 */
    CCP2CON = 0;            /* Stop PWM2 */
    TMR2 = 0;
    PR2  = PWM_PERIOD-1;
    CCPR1L = 0;
    CCPR1H = 0;
    CCPR2L = 0;
    CCPR2H = 0;
    CCP1CON = 0x0C;
    CCP2CON = 0x0C;
    TRISCbits.RC1 = 0;      /* make CCP1 an output */
    TRISCbits.RC2 = 0;      /* make CCP2 an output */
    T2CONbits.TMR2ON = 1;   /* start up PWMs */
    
}
/*
 * Set duty cycle of PWM1.
 * Input range 0 to 100 percent.
 */
void PWM_SetPwm1DutyCycle(unsigned char percent)
{
    unsigned int PwmDc;
    unsigned char PwmTemp;
    
    if (percent > 100) percent = 100;
    
    /* convert input from percent to PWM duty cycle units */
    PwmDc  = percent * PWM_PERIOD;
    PwmDc  = PwmDc / 25;
    
    /* put 2 LSBs in position to update the CCPRxL register */
    PwmTemp = PwmDc & 0x03;
    PwmTemp = ((PwmTemp>>4) | (PwmTemp<<4));
    PwmTemp = (PwmTemp ^ CCP1CON) & 0x30;
    
    /* update the PWM duty cycle registers */
    CCPR1L  = (unsigned char)(PwmDc >> 2);
    CCP1CON ^= PwmTemp;  
}
/* 
 * Set duty cycle of PWM2.
 * Input range 0 to 100 percent.
 */
void PWM_SetPwm2DutyCycle(unsigned char percent)
{
    unsigned int PwmDc;
    unsigned char PwmTemp;
    
    if (percent > 100) percent = 100;

    /* convert input from percent to PWM duty cycle units */
    PwmDc  = percent * PWM_PERIOD;
    PwmDc  = PwmDc / 25;

    /* put 2 LSBs in position to update the CCPRxL register */
    PwmTemp = PwmDc & 0x03;
    PwmTemp = ((PwmTemp>>4) | (PwmTemp<<4));
    PwmTemp = (PwmTemp ^ CCP2CON) & 0x30;
    
    /* update the PWM duty cycle registers */
    CCPR2L  = (unsigned char)(PwmDc >> 2);
    CCP2CON ^= PwmTemp;  
}
