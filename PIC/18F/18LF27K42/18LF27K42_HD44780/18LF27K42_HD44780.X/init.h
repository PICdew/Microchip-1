/* 
 * File:     init.h
 * Author:   dan1138
 * Target:   PIC18F27K42
 * Compiler: XC8 v1.45
 * IDE:      MPLABX v4.05
 *
 */

#ifndef INIT_H
#define	INIT_H

#include <xc.h>

#define FSYS (32000000L)
#define FCYC (FSYS/4L)
#define _XTAL_FREQ FSYS

void PIC_Init( void );

#endif

