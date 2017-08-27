/* 
 * File:     init.c
 * Target:   PIC16F690
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.65
 *
 */
#include "init.h"

#pragma config FOSC = INTRCIO   // Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA4/OSC2/CLKOUT pin, I/O function on RA5/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = ON       // MCLR Pin Function Select bit (MCLR pin function is MCLR)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown-out Reset Selection bits (BOR disabled)
#pragma config IESO = ON        // Internal External Switchover bit (Internal External Switchover mode is enabled)
#pragma config FCMEN = ON       // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is enabled)

void PIC_Init( void )
{
    OSCCON = 0b01110000;        // Select 8MHz internal oscillator
    
    INTCON  = 0x00;             // disable all interrupt sources
    PIE1    = 0x00; 
    PIE2    = 0x00; 
    T2CON   = 0x00;             // Turn off Timer2, prescale 1:4, postscale 1:1
    ADCON0  = 0x00;             // turn off ADC module
    ANSEL   = 0x00;             // make all Analog pins I/O digital
    ANSELH  = 0x00;             // make all Analog pins I/O digital
    VRCON   = 0x00;             // Turn off comparator voltage ref
    CM1CON0 = 0x00;             // Turn off comparator 1
    CM2CON0 = 0x00;             // Turn off comparator 2
    
    OPTION_REG = 0b11010010;    // PORTB weak pull ups disabled
                                // Interrupt on rising edge of RB0/INT pin
                                // T0 internal clock source
                                // T0 clock edge high-to-low
                                // Prescaler assigned to TIMER0
                                // Prescale 1:8 for TIMER0
}
