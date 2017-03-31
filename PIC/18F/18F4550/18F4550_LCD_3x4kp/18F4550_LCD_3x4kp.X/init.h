/*
 * File:   init.h
 * Author: 
 * Target: PIC18F4550
 *
 */
#ifndef INIT_H
#define INIT_H
/*   Specify the System clock frequency in Hz */
#define FSYS (48000000UL)
    
/*   Specify the Peripheral clock frequency in Hz */
#define FCYC (FSYS/4UL)

#define _XTAL_FREQ FSYS

void PIC_Init(void);

#endif
