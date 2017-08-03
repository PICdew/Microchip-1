/* 
 * File:     init.h
 * Target:   PIC16F690
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.65
 *
 */

#ifndef INIT_H
#define	INIT_H

#include <xc.h>

#define FSYS (8000000L)
#define FCYC (FSYS/4L)
#define MAJOR_REV (1)
#define MINOR_REV (0)
#define _XTAL_FREQ FSYS

void PIC_Init( void );

#endif

