/* Date: 
 * File: main.c
 * Target: PIC18F47J53
 * IDE: MPLAB v8.92
 * Compiler: XC8 v1.42
 *
 * Description:
 * Setup TIMER0 to interrupt after 16777216 clocks.
 * Setup TIMER2 to interrupt 250 times per second.
 * Toggle LEDs on the MikroElektronika PIC Clicker. https://download.mikroe.com/documents/starter-boards/clicker/pic/pic-clicker-manual-v101.pdf
 *
 *
 *                                                  PIC18F47J53
 *               +---------+               +---------+               +----------+               +---------+
 *    MOSI <>  1 : RC7     :      CS <> 12 : RB3     : 10uF CAP-> 23 : VCAP     :     RC0 <> 34 : RC0     :
 *     INT <>  2 : RD4     :         -- 13 : NC      :         <> 24 : RA5      :     RC1 <> 35 : RC1     :
 *      RX <>  3 : RD5     :     SCK <> 14 : RB4     :     RE0 <> 25 : RE0      :     RC2 <> 36 : RC2     :
 *      TX <>  4 : RD6     :    MISO <> 15 : RB5     :     RE1 <> 26 : RE1      :  VCC3V3 -> 37 : VUSB    :
 *         <>  5 : RD7     :     PGC <> 16 : RB6/PGC :     RE2 <> 27 : RE2      :     SCL <> 38 : RD0     :
 *     GND ->  6 : VSS1    :     PGD <> 17 : RB7/PGD :  VCC3V3 -> 28 : AVDD2    :     SDA <> 39 : RD1     :
 *  VCC3V3 ->  7 : AVDD1   :   MCLR# -> 18 : MCLR    :  VCC3V3 -> 29 : VDD2     :    RP19 <> 40 : RD2     :
 *  VCC3V3 ->  8 : VDD1    :     RP0 <> 19 : RA0     :     GND -> 30 : AVSS1    :    RP20 <> 41 : RD3     :
 *     RB0 <>  9 : RB0     :     RP1 <> 20 : RA1     :     GND -> 31 : VSS2     :      D- <> 42 : RC4/D-  :
 *     RB1 <> 10 : RB1     :      AN <> 21 : RA2     :     XTL <> 32 : RA7/OSC1 :      D+ <> 43 : RC5/D+  :
 *     RST <> 11 : RB2     :         <> 22 : RA3     :     XTL <> 33 : RA6/OSC2 :     PWM <> 44 : RC6     :
 *               +---------+               +---------+               +----------+               +---------+
 *                                                   QFN-44
 *
 */
#include <xc.h>
    
#pragma config WDTEN = OFF          /* Watchdog Timer (Disabled - Controlled by SWDTEN bit) */
#pragma config PLLDIV = 4           /* PLL Prescaler Selection (Divide by 4 (16 MHz oscillator input)) */
#pragma config CFGPLLEN = ON        /* PLL Enable Configuration Bit (PLL Enabled) */
#pragma config STVREN = ON          /* Stack Overflow/Underflow Reset (Enabled) */
#pragma config XINST = OFF          /* Extended Instruction Set (Disabled) */
#pragma config CPUDIV = OSC1        /* CPU System Clock Postscaler (No CPU system clock divide) */
#pragma config CP0 = OFF            /* Code Protect (Program memory is not code-protected) */
#pragma config OSC = HSPLL          /* Oscillator (HS+PLL, USB-HS+PLL) */
#pragma config SOSCSEL = LOW        /* T1OSC/SOSC Power Selection Bits (Low Power T1OSC/SOSC circuit selected) */
#pragma config CLKOEC = OFF         /* EC Clock Out Enable Bit  (CLKO output disabled on the RA6 pin) */
#pragma config FCMEN = OFF          /* Fail-Safe Clock Monitor (Disabled) */
#pragma config IESO = OFF           /* Internal External Oscillator Switch Over Mode (Disabled) */
#pragma config WDTPS = 32768        /* Watchdog Postscaler (1:32768) */
#pragma config DSWDTOSC = INTOSCREF /* DSWDT Clock Select (DSWDT uses INTRC) */
#pragma config RTCOSC = INTOSCREF   /* RTCC Clock Select (RTCC uses INTRC) */
#pragma config DSBOREN = OFF        /* Deep Sleep BOR (Disabled) */
#pragma config DSWDTEN = OFF        /* Deep Sleep Watchdog Timer (Disabled) */
#pragma config DSWDTPS = 8192       /* Deep Sleep Watchdog Postscaler (1:8,192 (8.5 seconds)) */
#pragma config IOL1WAY = OFF        /* IOLOCK One-Way Set Enable bit (The IOLOCK bit (PPSCON<0>) can be set and cleared as needed) */
#pragma config ADCSEL = BIT12       /* ADC 10 or 12 Bit Select (12 - Bit ADC Enabled) */
#pragma config MSSP7B_EN = MSK7     /* MSSP address masking (7 Bit address masking mode) */
#pragma config WPFP = PAGE_127      /* Write/Erase Protect Page Start/End Location (Write Protect Program Flash Page 127) */
#pragma config WPCFG = OFF          /* Write/Erase Protect Configuration Region  (Configuration Words page not erase/write-protected) */
#pragma config WPDIS = OFF          /* Write Protect Disable bit (WPFP<6:0>/WPEND region ignored) */
#pragma config WPEND = PAGE_0       /* Write/Erase Protect Region Select bit (valid when WPDIS = 0) (Pages 0 through WPFP<6:0> erase/write protected) */
#pragma config LS48MHZ = SYS48X8    /* Low Speed USB mode with 48 MHz system clock bit (System clock at 48 MHz USB CLKEN divide-by is set to 8) */
    
#define FOSC (48000000L)
#define FCYC (FOSC/4L)
    
#define  PPSUnLock()  do {EECON2 = 0x55; EECON2 = 0xAA; PPSCONbits.IOLOCK  = 0;} while (0)
#define  PPSLock()    do {EECON2 = 0x55; EECON2 = 0xAA; PPSCONbits.IOLOCK  = 1;} while (0)
#define  RTCCUnLock() do {EECON2 = 0x55; EECON2 = 0xAA; RTCCFGbits.RTCWREN = 1;} while (0)
#define  RTCCLock()   RTCCFGbits.RTCWREN=0
/*
 * define constants used to specify input pins
 */
enum
{       
    eRPI_RA0_RP0  = 0,  /* */
    eRPI_RA1_RP1 ,      /* */
    eRPI_RA5_RP2 ,      /* */
    eRPI_RB0_RP3 ,      /* */
    eRPI_RB1_RP4 ,      /* RTCC output */
    eRPI_RB2_RP5 ,      /* REFO output */
    eRPI_RB3_RP6 ,      /* */
    eRPI_RB4_RP7 ,      /* */
    eRPI_RB5_RP8 ,      /* */
    eRPI_RB6_RP9 ,      /* PGC */
    eRPI_RB7_RP10,      /* PGD */
    eRPI_RC0_RP11,      /* T1CKI input */
    eRPI_RC1_RP12,      /* */
    eRPI_RC2_RP13,      /* */
    eRPI_RC6_RP17 = 17, /* */
    eRPI_RC7_RP18,      /* */
    eRPI_RD2_RP19,      /* */
    eRPI_RD3_RP20,      /* */
    eRPI_RD4_RP21,      /* */
    eRPI_RD5_RP22,      /* */
    eRPI_RD6_RP23,      /* */
    eRPI_RD7_RP24,      /* */
    eRPI_NONE     = 0x1F
};  
/*
 * define constants used to specify output functions
 */
enum
{   
    eRPO_NONE       =  0,
    eRPO_C1OUT      =  1,
    eRPO_C2OUT      =  2,
    eRPO_C3OUT      =  3,
    eRPO_TX2        =  6,
    eRPO_DT2        =  7,
    eRPO_SDO2       = 10,
    eRPO_SCK2       = 11,
    eRPO_SSDMA      = 12,
    eRPO_ULPOUT     = 13,
    eRPO_CCP1       = 14,
    eRPO_CCP2       = 18,
    eRPO_CCP3       = 22,
    eRPO_P1A        = 14,
    eRPO_P1B        = 15,
    eRPO_P1C        = 16,
    eRPO_P1D        = 17,
    eRPO_P2A        = 18,
    eRPO_P2B        = 19,
    eRPO_P2C        = 20,
    eRPO_P2D        = 21,
    eRPO_P3A        = 22,
    eRPO_P3B        = 23,
    eRPO_P3C        = 24,
    eRPO_P3D        = 25 
};  
/*
 * Initialize this PIC hardware
 */    
void PIC_Init ( void )
{   
    INTCON        = 0;          /* Disable all interrupt sources */
    INTCON3       = 0;
    PIE1          = 0;
    PIE2          = 0;
    PIE3          = 0;
    PIE4          = 0;
    PIE5          = 0;
    
    OSCCON        = 0b01110000; /* Enter Sleep mode for sleep, */
                                /* set internal oscillator to 8MHz, */
                                /* use primary clock selected by config words */
    
    ANCON0        = 0b11111111; /* turn off all ADC inputs */
    ANCON1        = 0b00011111;
    
    CM1CON        = 0b00000000; /* Turn off all comparators */
    CM2CON        = 0b00000000;
    CM3CON        = 0b00000000;
    CVRCON        = 0b00000000;
    
    LATA          = 0b00000000;
    LATB          = 0b00000000;
    LATC          = 0b00000000;
    LATD          = 0b00000000;
    LATE          = 0b00000000;
    
    TRISA         = 0b11111111; /* set all pins a digital inputs */
    TRISB         = 0b11111111;
    TRISC         = 0b11111111;
    TRISD         = 0b11111111;
    TRISE         = 0b00000111;
    TRISEbits.RDPU = 0;         /* turn off PORTD pull-ups */
    TRISEbits.REPU = 0;         /* turn off PORTE pull-ups */
    INTCON2bits.RBPU = 1;       /* turn off PORTB pull-ups */
    
    RCONbits.IPEN = 1;      /* Enable High/Low interrupt priority model. */
    
    PPSUnLock();            /* unlock pin map */
    /*
     * Associate input functions with pins
     */
    RPINR1  = eRPI_NONE; /* INT1    */
    RPINR2  = eRPI_NONE; /* INT2    */
    RPINR3  = eRPI_NONE; /* INT3    */
    RPINR4  = eRPI_NONE; /* T0CKI   */
    RPINR6  = eRPI_NONE; /* T3CKI   */
    RPINR15 = eRPI_NONE; /* T5CKI   */
    RPINR7  = eRPI_NONE; /* CCP1    */
    RPINR8  = eRPI_NONE; /* CCP2    */
    RPINR9  = eRPI_NONE; /* CCP3    */
    RPINR12 = eRPI_NONE; /* T1G     */
    RPINR13 = eRPI_NONE; /* T3G     */
    RPINR14 = eRPI_NONE; /* T5G     */
    RPINR16 = eRPI_NONE; /* RX2     */
    RPINR17 = eRPI_NONE; /* CK2     */
    RPINR21 = eRPI_NONE; /* SDI2    */
    RPINR22 = eRPI_NONE; /* SCK2IN  */
    RPINR23 = eRPI_NONE; /* SS2IN   */
    RPINR24 = eRPI_NONE; /* FLT0    */
    /*
     * Associate output functions with pins
     */
    RPOR0   = eRPO_NONE; /* RA0 */
    RPOR1   = eRPO_NONE; /* RA1 */
    RPOR2   = eRPO_NONE; /* RA5 */
    RPOR3   = eRPO_NONE; /* RB0 */
    RPOR4   = eRPO_NONE; /* RB1 RTCC output*/
    RPOR5   = eRPO_NONE; /* RB2 */
    RPOR6   = eRPO_NONE; /* RB3 */
    RPOR7   = eRPO_NONE; /* RB4 */
    RPOR8   = eRPO_NONE; /* RB5 */
    RPOR9   = eRPO_NONE; /* RB6 PGC */
    RPOR10  = eRPO_NONE; /* RB7 PGD */
    RPOR11  = eRPO_NONE; /* RC0 T1CLKI */
    RPOR12  = eRPO_NONE; /* RC1 */
    RPOR13  = eRPO_NONE; /* RC2 */
    RPOR17  = eRPO_NONE; /* RC6 */
    RPOR18  = eRPO_NONE; /* RC7 */
    RPOR19  = eRPO_NONE; /* RD2 */
    RPOR20  = eRPO_NONE; /* RD3 */
    RPOR21  = eRPO_NONE; /* RD4 */
    RPOR22  = eRPO_NONE; /* RD5 */
    RPOR23  = eRPO_NONE; /* RD6 */
    RPOR24  = eRPO_NONE; /* RD7 */
    
    PPSLock();            /* lock pin map */
}   
/*
 * Setup TIMER0 to request an interrupt every 16777216 clocks. 
 * (16-bit count with 1:256 prescaler)
 *
 * With the system oscillator at 48MHz is 1.39810133... seconds.
 */    
void TIMER0_Init(void)
{
    INTCONbits.TMR0IE = 0;  /* disable timer0 interrupt */
    T0CON=0x00;             /* stop timer0 */
    TMR0H=0;                /* clear timer 0 count register */
    TMR0L=0;
    T0CON=0b00000111;       /* select TIMER0:
                             *  Mode 16-bit
                             *  Clock source internal instruction cycle clock
                             *  Assign prescaler to TIMER0
                             *  Set prescaler for 1:256
                             */
    INTCON2bits.TMR0IP = 1; /* select high priority for timer 0 */
    INTCONbits.TMR0IF  = 0; /* clear timer 0 interrupt request */
    INTCONbits.TMR0IE  = 1; /* enable timer 0 interrupts */
    T0CONbits.TMR0ON   = 1; /* turn on timer 0 */
}
/*
 * Setup TIMER2 to request an interrupt every 48000 clocks. 
 * Prescale 1:16, post scale 1:12, reload count 250
 *
 * With the system oscillator at 48MHz this is 250 interrupts per seconds.
 */    
void TIMER2_Init(void)
{
    PIE1bits.TMR2IE = 0;     /* disable timer2 interrupt */
    T2CON = 0x00;            /* stop timer2 */
    TMR2  = 0;               /* clear timer2 count register */
    PR2   = 249;             /* set timrt2 to reload after 250 clocks */
    T2CONbits.T2CKPS   = 2;  /* set timer2 prescale for 1:16 */
    T2CONbits.T2OUTPS  = 11; /* set timer2 postscale for 1:12 */
    IPR1bits.TMR2IP    = 0;  /* select low priority for timer2 */
    PIR1bits.TMR2IF    = 0;  /* clear timer2 interrupt request */
    PIE1bits.TMR2IE    = 1;  /* enable timer2 interrupts */
    T2CONbits.TMR2ON   = 1;  /* turn on timer2 */
}
/*
 * This is the main application loop
 */    
void main ( void )
{
    PIC_Init();
    TIMER0_Init();
    TIMER2_Init();
    
    INTCONbits.GIEL = 1;        /* Enable low priority interrupts */
    INTCONbits.GIEH = 1;        /* Enable high priority interrupts */

    /* Make GPIO bit to LD1 an output with LD1 off */    
    LATAbits.LATA0 = 0;
    TRISAbits.TRISA0 = 0;

    /* Make GPIO bit to LD2 an output with LD2 off */    
    LATAbits.LATA1 = 0;
    TRISAbits.TRISA1 = 0;

    for( ; ; ) 
    {
        Nop();
    }
}
/*
 * high priority interrupt handlers
 */    
void interrupt InterruptHandlerHigh( void )
{   
    if(INTCONbits.TMR0IE)
    {
        if(INTCONbits.TMR0IF)
        {
            INTCONbits.TMR0IF  = 0; /* clear timer 0 interrupt request */
            LATAbits.LATA0 ^= 1;    /* Toggle LD1 */
        }
    }
}   
/*
 * low priority interrupt handlers
 */    
void interrupt low_priority InterruptHandlerLow( void )
{   
    static unsigned char T2_InterruptCount;

    if(PIE1bits.TMR2IE)
    {
        if(PIR1bits.TMR2IF)
        {
            PIR1bits.TMR2IF    = 0; /* clear timer2 interrupt request */
            /*
             * Toggle an LED once per second.
             * TIMER2 is to be setup to assert 250 interrupts per second.
             */
            if (!T2_InterruptCount)
            {
                LATAbits.LATA1 ^= 1;    /* Toggle LD2 */
                T2_InterruptCount = 250;
            }
            T2_InterruptCount--;
        }
    }
}   
