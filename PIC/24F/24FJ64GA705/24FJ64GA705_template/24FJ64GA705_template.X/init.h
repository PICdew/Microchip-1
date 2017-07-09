/* 
 * File:   init.h
 * Target: PIC24FJ64GA705
 * Comments:
 * Revision history: 
 */

#ifndef INIT_H
#define	INIT_H
/* 
 * Define the target system clock frequency.
 * 
 * The initialization MUST set the system clock to support these definitions.
 * 
 */
#define FOSC (32000000UL)
#define FCYC (FOSC/2UL)

void PIC_Init( void );
void delay( unsigned short wait_ms );

#endif

