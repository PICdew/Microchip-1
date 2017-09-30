/* 
 * File:     init.c
 * Target:   PIC16F877A
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.65 
 *
 */
#include <stdbool.h>
#include "init.h"

#if defined(COMPILER_XC8)
 #if defined(TARGET_877A)
  #pragma config FOSC = HS        /* Oscillator Selection bits (HS oscillator) */
  #pragma config WDTE = OFF       /* Watchdog Timer Enable bit (WDT disabled) */
  #pragma config PWRTE = OFF      /* Power-up Timer Enable bit (PWRT disabled) */
  #pragma config BOREN = OFF      /* Brown-out Reset Enable bit (BOR disabled) */
  #pragma config LVP = OFF        /* Low-Voltage (Single-Supply) In-Circuit Serial Programming Enable bit (RB3 is digital I/O, HV on MCLR must be used for programming) */
  #pragma config CPD = OFF        /* Data EEPROM Memory Code Protection bit (Data EEPROM code protection off) */
  #pragma config WRT = OFF        /* Flash Program Memory Write Enable bits (Write protection off; all program memory may be written to by EECON control) */
  #pragma config CP = OFF         /* Flash Program Memory Code Protection bit (Code protection off) */
 #elif defined(TARGET_887)
  /* CONFIG1 */
  #pragma config FOSC = HS        /* Oscillator Selection bits (HS oscillator: High-speed crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN) */
  #pragma config WDTE = OFF       /* Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register) */
  #pragma config PWRTE = OFF      /* Power-up Timer Enable bit (PWRT disabled) */
  #pragma config MCLRE = ON       /* RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR) */
  #pragma config CP = OFF         /* Code Protection bit (Program memory code protection is disabled) */
  #pragma config CPD = OFF        /* Data Code Protection bit (Data memory code protection is disabled) */
  #pragma config BOREN = OFF      /* Brown Out Reset Selection bits (BOR disabled) */
  #pragma config IESO = OFF       /* Internal External Switchover bit (Internal/External Switchover mode is disabled) */
  #pragma config FCMEN = OFF      /* Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled) */
  #pragma config LVP = OFF        /* Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming) */

  /* CONFIG2 */
  #pragma config BOR4V = BOR40V   /* Brown-out Reset Selection bit (Brown-out Reset set to 4.0V) */
  #pragma config WRT = OFF        /* Flash Program Memory Self Write Enable bits (Write protection off) */
 #endif
#else
 #if defined (TARGET_877A)
  __CONFIG(FOSC_HS & WDTE_OFF & PWRTE_OFF & BOREN_OFF & LVP_OFF & CPD_OFF & WRT_OFF & CP_OFF);
 #elif defined (TARGET_887)
  __CONFIG(FOSC_HS & WDTE_OFF & PWRTE_OFF & MCLRE_ON & CP_OFF & CPD_OFF & BOREN_OFF & IESO_OFF & FCMEN_OFF & LVP_OFF);
  __CONFIG(BOR4V_BOR40V & WRT_OFF);
 #endif
#endif


void PIC_Init( void )
{
    /* Disable all interrupt sources */
    INTCON = 0;
    PIE1   = 0;
    PIE2   = 0;

    /*
     * Pull-ups off, INT edge low to high, WDT prescale 1:1
     * TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:4
     * TIMER0 will assert the overflow flag every 256*16 (4096)
     * instruction cycles, with a 20MHz oscilator this ia 0.8192 milliseconds.
     */
    OPTION_REG = 0b11000011;
    
    /* Make all GPIO pins digital */
#if defined (TARGET_877A)
    CMCON  = 0x07;
    ADCON1 = 0x06;
#elif defined(TARGET_887)
    ANSEL  = 0;
    ANSELH = 0;
#endif

}
