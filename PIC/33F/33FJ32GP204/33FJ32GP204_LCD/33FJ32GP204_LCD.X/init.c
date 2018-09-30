/*
 * File:   init.c
 * Target: dsPIC33FJ32GP204
 *
 */
// FBS
#pragma config BWRP = WRPROTECT_OFF     // Boot Segment Write Protect (Boot Segment may be written)
#pragma config BSS = NO_FLASH           // Boot Segment Program Flash Code Protection (No Boot program Flash segment)

// FGS
#pragma config GWRP = OFF               // General Code Segment Write Protect (User program memory is not write-protected)
#pragma config GSS = OFF                // General Segment Code Protection (User program memory is not code-protected)

// FOSCSEL
#pragma config FNOSC = FRC              // Oscillator Mode (Internal Fast RC (FRC))
#pragma config IESO = OFF               // Internal External Switch Over Mode (Start-up device with user-selected oscillator source)

// FOSC
#pragma config POSCMD = NONE            // Primary Oscillator Source (Primary Oscillator Disabled)
#pragma config OSCIOFNC = ON            // OSC2 Pin Function (OSC2 pin has digital I/O function)
#pragma config IOL1WAY = OFF            // Peripheral Pin Select Configuration (Allow Multiple Re-configurations)
#pragma config FCKSM = CSECMD           // Clock Switching and Monitor (Clock switching is enabled, Fail-Safe Clock Monitor is disabled)

// FWDT
#pragma config WDTPOST = PS32768        // Watchdog Timer Postscaler (1:32,768)
#pragma config WDTPRE = PR128           // WDT Prescaler (1:128)
#pragma config WINDIS = OFF             // Watchdog Timer Window (Watchdog Timer in Non-Window mode)
#pragma config FWDTEN = OFF             // Watchdog Timer Enable (Watchdog timer enabled/disabled by user software)

// FPOR
#pragma config FPWRT = PWR128           // POR Timer Value (128ms)
#pragma config ALTI2C = OFF             // Alternate I2C  pins (I2C mapped to SDA1/SCL1 pins)

// FICD
#pragma config ICS = PGD1               // Comm Channel Select (Communicate on PGC1/EMUC1 and PGD1/EMUD1)
#pragma config JTAGEN = OFF             // JTAG Port Enable (JTAG is Disabled)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>
#include "init.h"

/* Initialize this PIC */ 
void PIC_Init(void) 
{   
    unsigned int ClockSwitchTimeout;

    /* 
    ** Disable all interrupt sources 
    */ 
    __builtin_disi(0x3FFF); /* disable interrupts for 16383 cycles */ 
    IEC0 = 0; 
    IEC1 = 0; 
    IEC4 = 0; 
    __builtin_disi(0x0000); /* enable interrupts */ 
    
    /*
     * At Power On Reset the configuration words set the system clock
     * to use the FRC oscillator. At this point we need to enable the
     * PLL to get the system clock running at 32MHz.
     * 
     * Clock switching on the dsPIC33FJ family with the PLL can be a bit tricky.
     * 
     * First we need to check if the configuration words enabled clock
     * switching at all, then turn off the PLL, then setup the PLL and
     * finally enable it. Sounds simple, I know. Make sure you verify this 
     * clock setup on the real hardware.
     */
    if(!OSCCONbits.CLKLOCK) /* if primary oscillator switching is unlocked */
    {
        /* Select primary oscillator as FRC */
        __builtin_write_OSCCONH(0b000);

        /* Request switch primary to new selection */
        __builtin_write_OSCCONL(OSCCON | (1 << _OSCCON_OSWEN_POSITION));

        /* wait, with timeout, for clock switch to complete */
        for(ClockSwitchTimeout=60000; --ClockSwitchTimeout && OSCCONbits.OSWEN;);

        /* setup PLL to run the system clock at the configured frequency */
        CLKDIV   = 0x0000; /* Set DOZE 1:1, DOZE disabled, FRCDIV 1:1, PLLPRE 1:2, PLLPOST 1:2 */
        
        /* Configure PLL prescaler, PLL postscaler, PLL divisor */
        PLLFBD   = PLL_M-2;
#if   PLL_N2==2
        CLKDIVbits.PLLPOST=0; /* N2=2 */
#elif PLL_N2==4
        CLKDIVbits.PLLPOST=1; /* N2=4 */
#elif PLL_N2==8
        CLKDIVbits.PLLPOST=3; /* N2=8 */
#else
#error invalid PLL_N2 paramenter
#endif
        CLKDIVbits.PLLPRE=PLL_N1-2;

        /* Select primary oscillator as FRCPLL */
        __builtin_write_OSCCONH(0b001);
        
        /* Request switch primary to new selection */
        __builtin_write_OSCCONL(OSCCON | (1 << _OSCCON_OSWEN_POSITION));
        
        /* wait, with timeout, for clock switch to complete */
        for(ClockSwitchTimeout=60000; --ClockSwitchTimeout && OSCCONbits.OSWEN;);

        /* wait, with timeout, for the PLL to lock */
        for(ClockSwitchTimeout=60000; --ClockSwitchTimeout && !OSCCONbits.LOCK;);
        
        /* at this point the system oscillator should be 32MHz */
    }

    /* Disable analog mode for all GPIOs */
    AD1PCFGL = 0xFFFF;
    
    _NSTDIS = 1;    /* disable interrupt nesting */ 

    /* set all GPIOs as inputs */
    TRISA   = 0xFFFF; 
    TRISB   = 0xFFFF; 
    TRISC   = 0xFFFF; 
    
}
