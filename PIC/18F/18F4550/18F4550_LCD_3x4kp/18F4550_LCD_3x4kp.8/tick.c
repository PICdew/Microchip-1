/*
 * File:   tick.c
 * Author: 
 *
 * Target: PIC18F4550
 */

#include <xc.h>
#include "tick.h"

/*
 * Setup TIMER0 to assert an interrupt every 16384 instruction cycles
 */
void Tick_Init(void)
{
    INTCONbits.TMR0IE = 0;
    T0CON = 0b11000101;     /* TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:64      */
    TMR0 = 0;               /* TIMER0 will assert the overflow flag every 256*64 (16384)              */
    INTCONbits.TMR0IF = 0;  /* instruction cycles, with a 12MHz oscilator this is 1.365 milliseconds. */
    INTCONbits.TMR0IE = 1;
    return;
}
