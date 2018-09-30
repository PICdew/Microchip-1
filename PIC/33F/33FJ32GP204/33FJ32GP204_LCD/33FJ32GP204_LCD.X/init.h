/*
 * File:   init.h
 * Author: 
 * Target: dsPIC33FJ32GP204
 *
 */

#ifndef INIT_H
#define INIT_H
#ifdef __cplusplus  // Provide C++ Compatibility

    extern "C" {

#endif

/* 
 * Define the target system clock frequency.
 * 
 * The initialization code MUST set the system clock to implement these definitions.
 * 
 */
/* Setup the clock to run at about 78.6432 MHz (39.3216 MIPS) from 7.3728MHz internal oscillator */
#define FSRC  (7372800ul)    /* nominal fast RC frequency */
#define PLL_N1 (3ul)         /* PLLPRE  CLKDIV<4:0> range 2 to 33 */
#define PLL_M  (64ul)        /* PLLDIV  PLLFBD<8:0> range 2 to 513 */
#define PLL_N2 (2ul)         /* PLLPOST CLKDIV<7:6> range 2, 4 or 8 */
#define FSYS (FSRC*PLL_M/(PLL_N1*PLL_N2))
#define FCY  (FSYS/2ul)

void PIC_Init(void);

#ifdef __cplusplus  // Provide C++ Compatibility

    }

#endif
    
/* Include target specific definitions */
#include <xc.h>
#include <libpic30.h>

#endif
