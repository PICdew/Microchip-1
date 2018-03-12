/*
 * File:   init.h
 * Author: 
 * Target: PIC18F24K20, PIC18F2520
 *
 */
#ifndef INIT_H
#define INIT_H
#include <xc.h>
#include <stddef.h>

/*   Specify the System clock frequency in Hz */
#define FSYS (500000ul)
/*   Specify PIC18F internal oscillator fresuency */
#define OSCCON_INIT (0x30)
    
/*   Specify the Peripheral clock frequency in Hz */
#define FCYC (FSYS/4ul)

#define _XTAL_FREQ FSYS

/*   Specify the TIMER0 prescale and keypad matrix debounce count based on the system clock frequency */
#if   (FSYS >= 8000000ul)
#define  T0CON_INIT (0b11000010u) /* TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:8       */
#define KP_DEBOUNCE_COUNT (16)
#elif (FSYS >= 4000000ul)
#define  T0CON_INIT (0b11000001u) /* TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:4       */
#define KP_DEBOUNCE_COUNT (16)
#elif (FSYS >= 2000000ul)
#define  T0CON_INIT (0b11000000u) /* TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:2       */
#define KP_DEBOUNCE_COUNT (16)
#elif (FSYS >= 1000000ul)
#define  T0CON_INIT (0b11001111u) /* TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:1       */
#define KP_DEBOUNCE_COUNT (16)
#elif (FSYS >=  500000ul)
#define  T0CON_INIT (0b11001111u) /* TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:1       */
#define KP_DEBOUNCE_COUNT (12)
#elif (FSYS >=  250000ul)
#define  T0CON_INIT (0b11001111u) /* TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:1       */
#define KP_DEBOUNCE_COUNT (8)
#elif (FSYS >=  125000ul)
#define  T0CON_INIT (0b11001111u) /* TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:1       */
#define KP_DEBOUNCE_COUNT (6)
#else 
#define  T0CON_INIT (0b11001111u) /* TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:1       */
#define KP_DEBOUNCE_COUNT (3)
#endif

void PIC_Init(void);

#endif
