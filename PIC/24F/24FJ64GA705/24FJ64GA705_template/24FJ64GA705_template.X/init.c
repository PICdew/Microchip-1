/* 
 * File:   init.c
 * Target: PIC24FJ64GA705
 * Comments:
 *                                                   PIC24F64GA705
 *              +------------+              +------------+              +------------+              +------------+
 *        <>  1 : RB9/RP9    :        <> 13 : RA10/RP28  :        <> 25 : RB2/RP2    :        <> 37 : RA4/SOSCO  :
 *        <>  2 : RC6/RP22   :        <> 14 : RA7        :        <> 26 : RB3/RP3    :        <> 38 : RA9        :
 *        <>  3 : RC7/RP23   :        <> 15 : RB14/RP14  :        <> 27 : RC0/RP16   :        <> 39 : RC3/RP19   :
 *        <>  4 : RC8/RP24   :        <> 16 : RB15/RP15  :        <> 28 : RC1/RP17   :        <> 40 : RC4/RP20   :
 *        <>  5 : RC9/RP25   :        -> 17 : AVSS       :        <> 29 : RC2/RP18   :        <> 41 : RC5/RP21   :
 *        ->  6 : VSS        :        -> 18 : AVDD       :        -> 30 : VDD        :        -> 42 : VSS        :
 *        ->  7 : VCAP       :        -> 19 : MCLR       :        -> 31 : VSS        :        -> 43 : VDD        :
 *        <>  8 : RA11/RPI29 :        <> 20 : RA12/RPI30 :        <> 32 : RA13/RPI31 :        <> 44 : RA14/RPI32 :
 *        <>  9 : RB10/PGD2  :        <> 21 : RA0/RP26   :        <> 33 : RA2/OSCI   :        <> 45 : RB5/PGD3  :
 *        <> 10 : RB11/PGC2  :        <> 22 : RA1/RP27   :        <> 34 : RA3/OSCO   :        <> 46 : RB6/PGC3   :
 *        <> 11 : RB12/RP12  :        <> 23 : RB0/PGD1   :        <> 35 : RA8        :        <> 47 : RB7/INT0   :
 *        <> 12 : RB13/RP13  :        <> 24 : RB1/PGC1   :        <> 36 : RB4/SOSCI  :        <> 48 : RB8/RP8    :
 *              +------------+              +------------+              +------------+              +------------+
 *                                                     TQFP-48
 * Revision history: 
 */
/*
 * Configuration words for PIC24FJ64GA705
 */
#pragma config BWRP = OFF               /* Boot Segment Write-Protect bit (Boot Segment may be written) */
#pragma config BSS = DISABLED           /* Boot Segment Code-Protect Level bits (No Protection (other than BWRP)) */
#pragma config BSEN = OFF               /* Boot Segment Control bit (No Boot Segment) */
#pragma config GWRP = OFF               /* General Segment Write-Protect bit (General Segment may be written) */
#pragma config GSS = DISABLED           /* General Segment Code-Protect Level bits (No Protection (other than GWRP)) */
#pragma config CWRP = OFF               /* Configuration Segment Write-Protect bit (Configuration Segment may be written) */
#pragma config CSS = DISABLED           /* Configuration Segment Code-Protect Level bits (No Protection (other than CWRP)) */
#pragma config AIVTDIS = OFF            /* Alternate Interrupt Vector Table bit (Disabled AIVT) */
#pragma config BSLIM = 0x1FFF           /* Boot Segment Flash Page Address Limit bits (Boot Segment Flash page address  limit) */
#pragma config FNOSC = FRC              /* Oscillator Source Selection (Internal Fast RC (FRC)) */
#pragma config PLLMODE = PLL4X          /* PLL Mode Selection (4x PLL selected) */
#pragma config IESO = OFF               /* Two-speed Oscillator Start-up Enable bit (Start up with user-selected oscillator source) */
#pragma config POSCMD = NONE            /* Primary Oscillator Mode Select bits (Primary Oscillator disabled) */
#pragma config OSCIOFCN = ON            /* OSC2 Pin Function bit (OSC2 is general purpose digital I/O pin) */
#pragma config SOSCSEL = ON             /* SOSC Power Selection Configuration bits (SOSC is used in crystal (SOSCI/SOSCO) mode) */
#pragma config PLLSS = PLL_PRI          /* PLL Secondary Selection Configuration bit (PLL is fed by the Primary oscillator) */
#pragma config IOL1WAY = OFF            /* Peripheral pin select configuration bit (Allow multiple reconfigurations) */
#pragma config FCKSM = CSECMD           /* Clock Switching Mode bits (Clock switching is enabled,Fail-safe Clock Monitor is disabled) */
#pragma config WDTPS = PS32768          /* Watchdog Timer Postscaler bits (1:32,768) */
#pragma config FWPSA = PR128            /* Watchdog Timer Prescaler bit (1:128) */
#pragma config FWDTEN = ON_SWDTEN       /* Watchdog Timer Enable bits (WDT Enabled/Disabled (controlled using SWDTEN bit)) */
#pragma config WINDIS = OFF             /* Watchdog Timer Window Enable bit (Watchdog Timer in Non-Window mode) */
#pragma config WDTWIN = WIN25           /* Watchdog Timer Window Select bits (WDT Window is 25% of WDT period) */
#pragma config WDTCMX = WDTCLK          /* WDT MUX Source Select bits (WDT clock source is determined by the WDTCLK Configuration bits) */
#pragma config WDTCLK = LPRC            /* WDT Clock Source Select bits (WDT uses LPRC) */
#pragma config BOREN = OFF              /* Brown Out Enable bit (Brown Out Disabled) */
#pragma config LPCFG = OFF              /* Low power regulator control (No Retention Sleep) */
#pragma config DNVPEN = ENABLE          /* Downside Voltage Protection Enable bit (Downside protection enabled using ZPBOR when BOR is inactive) */
#pragma config ICS = PGD1               /* ICD Communication Channel Select bits (Communicate on PGEC1 and PGED1) */
#pragma config JTAGEN = OFF             /* JTAG Enable bit (JTAG is disabled) */
#pragma config ALTCMPI = DISABLE        /* Alternate Comparator Input Enable bit (C1INC, C2INC, and C3INC are on their standard pin locations) */
#pragma config TMPRPIN = OFF            /* Tamper Pin Enable bit (TMPRN pin function is disabled) */
#pragma config SOSCHP = OFF             /* SOSC High Power Enable bit (valid only when SOSCSEL = 1 (Enable SOSC low power mode) */
#pragma config ALTI2C1 = ALTI2CEN       /* Alternate I2C pin Location (SDA1 and SCL1 on RB9 and RB8) */
/*
 * 
 */
#include <xc.h>
#include "init.h"
/*
 * 
 */
void PIC_Init( void )
{
    unsigned int ClockSwitchTimeout;

    /* 
     * Disable all interrupt sources 
     */ 
    __builtin_disi(0x3FFF); /* disable interrupts for 16383 cycles */ 
    IEC0 = 0; 
    IEC1 = 0; 
    IEC2 = 0; 
    IEC3 = 0; 
    IEC4 = 0; 
    IEC5 = 0; 
    IEC6 = 0; 
    IEC7 = 0; 
    __builtin_disi(0x0000); /* enable interrupts */ 
    /*
     * At Power On Reset the configuration words set the system clock
     * to use the FRC oscillator. At this point we need to enable the
     * PLL to get the system clock running at 32MHz.
     * 
     * Clock switching on the 24FJ family with the PLL can be a bit tricky.
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
        for(ClockSwitchTimeout=10000; --ClockSwitchTimeout && OSCCONbits.OSWEN;);

        CLKDIV   = 0x0000; /* set for FRC clock 8MHZ operations */

        /* Select primary oscillator as FRCPLL */
        __builtin_write_OSCCONH(0b001);
        /* Request switch primary to new selection */
        __builtin_write_OSCCONL(OSCCON | (1 << _OSCCON_OSWEN_POSITION));
        
        /* ALERT: This may be required only when the 96MHz PLL is used */
        CLKDIVbits.PLLEN = 1;

        /* wait, with timeout, for clock switch to complete */
        for(ClockSwitchTimeout=10000; --ClockSwitchTimeout && OSCCONbits.OSWEN;);

        /* wait, with timeout, for the PLL to lock */
        for(ClockSwitchTimeout=10000; --ClockSwitchTimeout && !OSCCONbits.LOCK;);
        
        /* at this point the system oscillator should be 32MHz */
    }
    /*
     * Set all GPIOs for digital I/O
     */
    ANSA   =  0x0000;
    ANSB   =  0x0000;
    ANSC   =  0x0000;
    /*
     * Disable voltage compairitors
     */
    CM1CON  = 0x0000; 
    CM2CON  = 0x0000; 
    CM3CON  = 0x0000; 
    /*
     * Disable interrupt nexting
     */
    _NSTDIS = 1;
    /*
     * Set all GPIOs as inputs
     */
    TRISA   = 0xFFFF; 
    TRISB   = 0xFFFF; 
    TRISC   = 0xFFFF; 
    /*
     * Map I/O functions to GPIO pins
     */
    __builtin_write_OSCCONL(OSCCON & ~(1 << _OSCCON_IOLOCK_POSITION)); /* Unlock PPS Registers */
    
    /* map GPIO inputs */ 
    _OCTRIG1R = 0x3FU; /* Output Compare Trigger 1     */    
    _INT1R    = 0x3FU; /* External Interrupt 1         */    
    _INT2R    = 0x3FU; /* External Interrupt 2         */
    _INT3R    = 0x3FU; /* External Interrupt 3         */
    _INT4R    = 0x3FU; /* External Interrupt 4         */
    _OCTRIG2R = 0x3FU; /* Output Compare Trigger 2     */    
    _T2CKR    = 0x3FU; /* Timer2 External Clock        */
    _T3CKR    = 0x3FU; /* Timer3 External Clock        */
    _ICM1R    = 0x3FU; /* Input Capture 1              */
    _ICM2R    = 0x3FU; /* Input Capture 2              */
    _ICM3R    = 0x3FU; /* Input Capture 3              */
    _ICM4R    = 0x3FU; /* Input Capture 4              */
    _IC1R     = 0x3FU; /* Input Capture 1              */
    _IC2R     = 0x3FU; /* Input Capture 2              */
    _IC3R     = 0x3FU; /* Input Capture 3              */
    _OCFAR    = 0x3FU; /* Output Compare Fault A       */
    _OCFBR    = 0x3FU; /* Output Compare Fault B       */
    _TCKIAR   = 0x3FU; /* CCP Clock Input A            */
    _TCKIBR   = 0x3FU; /* CCP Clock Input B            */
    _U1RXR    = 0x3FU; /* UART1 Clear To Send          */
    _U1CTSR   = 0x3FU; /* UART1 Receive                */
    _U2RXR    = 0x3FU; /* UART2 Clear To Send          */
    _U2CTSR   = 0x3FU; /* UART2 Receive                */
    _SDI1R    = 0x3FU; /* SPI1 Data Input              */
    _SCK1R    = 0x3FU; /* SPI1 Clock Input             */
    _SS1R     = 0x3FU; /* SPI1 Slave Select Input      */
    _SDI2R    = 0x3FU; /* SPI2 Data Input              */
    _SCK2R    = 0x3FU; /* SPI2 Clock Input             */
    _SS2R     = 0x3FU; /* SPI2 Slave Select Input      */
    _TXCKR    = 0x3FU; /* Generic Timer External Clock */
    _CLCINAR  = 0x3FU; /* CLC Input A                  */
    _CLCINBR  = 0x3FU; /* CLC Input B                  */
    _SDI3R    = 0x3FU; /* SPI3 Data Input              */
    _SCK3R    = 0x3FU; /* SPI3 Clock Input             */
    _SS3R     = 0x3FU; /* SPI3 Slave Select Input      */

    /* map GPIO outputs */ 
    _RP0R     = 0x00U; /* RB0/PGD1                     */
    _RP1R     = 0x00U; /* RB1/PGC1                     */
    _RP2R     = 0x00U; /* RB2                          */
    _RP3R     = 0x00U; /* RB3                          */
    _RP4R     = 0x00U; /* RB4/SOSCI                    */
    _RP5R     = 0x00U; /* RB5/PGD3                     */
    _RP6R     = 0x00U; /* RB6/PGC3                     */
    _RP7R     = 0x00U; /* RB7/INT0                     */
    _RP8R     = 0x00U; /* RB8                          */
    _RP9R     = 0x00U; /* RB9                          */
    _RP10R    = 0x00U; /* RB10/PGD2                    */
    _RP11R    = 0x00U; /* RB11/PGC2                    */
    _RP12R    = 0x00U; /* RB12                         */
    _RP13R    = 0x00U; /* RB13                         */
    _RP14R    = 0x00U; /* RB14                         */
    _RP15R    = 0x00U; /* RB15                         */
    _RP16R    = 0x00U; /* RC0                          */
    _RP17R    = 0x00U; /* RC1                          */
    _RP18R    = 0x00U; /* RC2                          */
    _RP19R    = 0x00U; /* RC3                          */
    _RP20R    = 0x00U; /* RC4                          */
    _RP21R    = 0x00U; /* RC5                          */
    _RP22R    = 0x00U; /* RC6                          */
    _RP23R    = 0x00U; /* RC7                          */
    _RP24R    = 0x00U; /* RC8                          */
    _RP25R    = 0x00U; /* RC9                          */
    _RP26R    = 0x00U; /* RA0                          */
    _RP27R    = 0x00U; /* RA1                          */
    _RP28R    = 0x00U; /* RA10                         */

    __builtin_write_OSCCONL(OSCCON | (1 << _OSCCON_IOLOCK_POSITION)); /* Lock PPS Registers */ 
}
/*
 * WARNING: non-portable function. For PIC24FJ targets.
 *
 * This function waits for the at least the specified number milliseconds then returns.
 */
void delay( unsigned short wait_ms )
{
    if(wait_ms--)
    {
        if(wait_ms)
        {
            do
            {
                asm("    repeat  %0 \n" 
                    "    clrwdt     \n"
                    : /* no outputs */ 
                    : "r" (FCYC/1000-6)
                    ); 
        
            } while(--wait_ms);
        }
        asm("    repeat  %0 \n" 
            "    clrwdt     \n"
            : /* no outputs */ 
            : "r" (FCYC/1000-17)
            ); 
    }
}    
