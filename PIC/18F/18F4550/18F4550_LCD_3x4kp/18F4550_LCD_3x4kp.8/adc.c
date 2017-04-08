/*
 * File:   adc.c
 * Author: 
 *
 * Target: PIC18F4550
 */

#include <xc.h>
#include "adc.h"

void ADC_Init(void)
{
    PIE1bits.ADIE = 0;              /* disable ADC interrupt */
    ADCON0 = 0;                     /* Turn off ADC */
    TRISA |= 0b00101111;            /* Make AN0-AN4 inputs */
    TRISE |= 0b00000111;            /* Make AN5-AN7 inputs */
    ADCON1 = 0x07;                  /* Make RA0,RA1,RA2,RA3,RA5,RE0,RE1,RE2 analog inputs */
    ADCON2 = 0b10011110;            /* Right justified, ACQ time 6-TAD, TAD = FSYS/64 */
    ADCON0bits.ADON = 1;            /* Turn on ADC */
}

unsigned int ADC_ReadChannel(unsigned char Channel)
{
    union 
    {
        unsigned int Word;
        struct
        {
            unsigned char B0;
            unsigned char B1;
        };
    } Result;

    while(ADCON0bits.NOT_DONE);     /* Wait for any conversions to complete */
    ADCON0bits.CHS = Channel;       /* Select channel for next conversion */
    ADCON0bits.GO = 1;              /* Start conversion */
    while(ADCON0bits.NOT_DONE);     /* Wait for results */
    
    Result.B0 = ADRESL;
    Result.B1 = ADRESH;

    return Result.Word;
}
