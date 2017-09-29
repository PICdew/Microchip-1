/* 
 * File:     buttons.h
 * Target:   PIC16F877A
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.61
 *
 */

#ifndef BUTTONS_H
#define BUTTONS_H

#define ButtonS2 PORTAbits.RA4
#define ButtonS3 PORTAbits.RA5
#define ButtonS2_DIR TRISAbits.TRISA4
#define ButtonS3_DIR TRISAbits.TRISA5

#define BUTTON_DEBOUNCE_TIME    (20)
#define BUTTON_S2_CHANGE_MASK   (0x10)
#define BUTTON_S3_CHANGE_MASK   (0x20)
#define BUTTON_S2_STATE_MASK    (0x01)
#define BUTTON_S3_STATE_MASK    (0x02)

unsigned char Buttons_GetStatus( void );
unsigned char Buttons_Poll( void );
void Buttons_Init( void );

#endif

