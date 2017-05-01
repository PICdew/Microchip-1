/*
 * File: main.c
 * Target: PIC18F46J50
 * IDE: MPLAB v8.92
 * Compiler: XC8 v1.38
 *
 * Description:
 *  This is an application to show using the
 *  deep sleep watch dog timeout to wake up
 *  after about 135 seconds.
 *
 *                                              PIC18F46J50 
 *             +---------+             +---------+             +----------+              +---------+
 *      <*>  1 : RC7/RX1 :      --- 12 : NC      : 10uF --> 23 : VCAP     :       --- 34 : NC      :
 *      <*>  2 : RD4/RP21:      --- 13 : NC      :      < > 24 : RA5/RP2  :       < > 35 : RC1/RP12:
 *      <*>  3 : RD5/RP22:      <*> 14 : RB4/RP7 :      < > 25 : RE0      :       < > 36 : RC2/RP13:
 *      <*>  4 : RD6/RP23:      <*> 15 : RB5/RP8 :      < > 26 : RE1      : 220nF --> 37 : VUSB    :
 *      <*>  5 : RD7/RP24:      <*> 16 : RB6/PGC :      < > 27 : RE2      :       <*> 38 : RD0/SCL2:
 *  GND -->  6 : VSS     :      <*> 17 : RB7/PGD :  PWR --> 28 : VDD      :       <*> 39 : RD1/SDA2:
 *  PWR -->  7 : VDD     :      --> 18 : MCLR    :  GND --> 29 : VSS      :       <*> 40 : RD2/RP19:
 *  SW1 < >  8 : RB0/INT0:      < > 19 : RA0/RP0 :      --> 30 : RA7/OSC1 :       <*> 41 : RD3/RP20:
 *      < >  9 : RB1/RP4 :      < > 20 : RA1/RP1 :      <-- 31 : RA6/OSC2 :       < > 42 : RC4/D-  :
 *      < > 10 : RB2/RP5 :      < > 21 : RA2     :      < > 32 : RC0/RP11 :       < > 43 : RC5/D+  :
 *      < > 11 : RB3/RP6 :      < > 22 : RA3     :      --- 33 : NC       :       <*> 44 : RC6/TX1 :
 *             +---------+             +---------+             +----------+              +---------+
 *                                               TQFP-44
 * Legend:
 *  <*> = I/O, 5 volt tolerant, Output must be open drain with pull up.
 *  --> = Input only.
 *  <-- = Output only.
 *  < > = I/O, 3.3 volt.
 *
 */
#define COMPILER_NOT_FOUND
    
#ifdef __XC8
#undef COMPILER_NOT_FOUND
#define COMPILER_XC8
#include <xc.h>
#else
 #ifdef __PICC18__
 #undef COMPILER_NOT_FOUND
 #define COMPILER_HTC
 #include <htc.h>
 #else
  #if __18CXX
  #undef COMPILER_NOT_FOUND
  #define COMPILER_C18
  #include <p18cxxx.h>
  #endif
 #endif
#endif
    
#ifdef COMPILER_NOT_FOUND
#error "Unknown compiler. Code builds with XC8, HTC or C18"
#endif
    
#pragma config WDTEN = OFF, PLLDIV = 2, STVREN = ON, XINST = OFF, CPUDIV = OSC1
#pragma config CP0 = OFF, OSC = INTOSC, T1DIG = OFF, LPT1OSC = OFF, WDTPS = 1
#pragma config FCMEN = OFF, IESO = OFF, DSWDTOSC = INTOSCREF, RTCOSC = T1OSCREF
#pragma config DSBOREN = OFF, DSWDTEN = ON, DSWDTPS = 8192, IOL1WAY = OFF
#pragma config MSSP7B_EN = MSK7, WPFP = PAGE_31, WPEND = PAGE_WPFP
#pragma config WPCFG = OFF, WPDIS = OFF
    
#define PLLX 1
#define FOSC (8000000L * PLLX)
#define FCYC (FOSC/4L)
#define _XTAL_FREQ FOSC
/*
 * Enumerate reasons we wake up
 */
typedef enum { ePOR, eWDTO, eDSPOR, eDSWDTO, eDSWINT0 } eWakeReason;

#ifdef COMPILER_C18
#pragma udata access ISR_Data
    
/*  
** Interrupt code for Microchip C18 compiler
*/  
#pragma code high_vector=0x08
#pragma interrupt C18_ISR_Handler
void C18_ISR_Handler(void) {
    /* hang forever is an interrupt asserts */
    for(;;)
    {
    }
}   
    
#pragma code /* return to the default code section */
#pragma udata /* return to the default data section */
    
#endif
    
#ifdef COMPILER_XC8
/*  
** Interrupt code for Microchip XC8 compiler
*/  
void interrupt XC8_ISR_Handler(void) {
    /* hang forever is an interrupt asserts */
    for(;;)
    {
    }
}   
    
#endif
    
#ifdef COMPILER_HTC
/*  
** Interrupt code for HI-TECH PICC-18 compiler
*/  
void interrupt HTC_ISR_Handler(void) {
    /* hang forever is an interrupt asserts */
    for(;;)
    {
    }
}   
    
#endif
    
/*  
** Initialize this PIC hardware
**  
*/  
unsigned char PIC_Init(void)
{   
    register eWakeReason Result;

    enum
    {   
        eRPI_RP0 = 0,   /* pin RA0      */
        eRPI_RP1 ,      /* pin RA1      */
        eRPI_RP2 ,      /* pin RA5      */
        eRPI_RP3 ,      /* pin RB0      */
        eRPI_RP4 ,      /* pin RB1      */
        eRPI_RP5 ,      /* pin RB2 REFO */
        eRPI_RP6 ,      /* pin RB3      */
        eRPI_RP7 ,      /* pin RB4      */
        eRPI_RP8 ,      /* pin RB5      */
        eRPI_RP9 ,      /* pin RB6 PGC  */
        eRPI_RP10,      /* pin RB7 PGD  */
        eRPI_RP11,      /* pin RC0      */
        eRPI_RP12,      /* pin RC1      */
        eRPI_RP13,      /* pin RC2      */
        eRPI_RP17 = 17, /* pin RC6 TX1  */
        eRPI_RP18,      /* pin RC7 RX1  */
        eRPI_RP19,      /* pin RD2      */
        eRPI_RP20,      /* pin RD3      */
        eRPI_RP21,      /* pin RD4      */
        eRPI_RP22,      /* pin RD5      */
        eRPI_RP23,      /* pin RD6      */
        eRPI_RP24,      /* pin RD7      */
        eRPI_NONE = 0x1F
    };  
        
    enum
    {   
        eRPO_NONE   =  0,
        eRPO_C1OUT  =  1,
        eRPO_C2OUT  =  2,
        eRPO_TX2    =  5,
        eRPO_DT2    =  6,
        eRPO_SDO2   =  9,
        eRPO_SCK2   = 10,
        eRPO_SSDMA  = 12,
        eRPO_ULPOUT = 13,
        eRPO_CCP1   = 14,
        eRPO_P1A    = 14,
        eRPO_P1B    = 15,
        eRPO_P1C    = 16,
        eRPO_P1D    = 17,
        eRPO_CCP2   = 18,
        eRPO_P2A    = 18,
        eRPO_P2B    = 19,
        eRPO_P2C    = 20,
        eRPO_P2D    = 21,
    };  
    
    INTCON  &= ~0xF8;           /* Disable all interrupt sources */
    INTCON3 &= ~0x38;
    PIE1 = 0;
    PIE2 = 0;
    PIE3 = 0;
    RCONbits.IPEN = 0;          /* Use legacy interrupt priority model */
    
    OSCCON        = 0b01110000; /* Set internal oscillator to 8MHz, use oscillator set by config words */
#if PLLX == 1
    OSCTUNEbits.PLLEN = 0; /* Do not use PLL */
#else
    OSCTUNEbits.PLLEN = 1; /* Use PLL */
#endif
    
    ANCON0        = 0b11111111; /* turn off all ADC inputs */
    ANCON1        = 0b00011111;
    
    CM1CON        = 0b00000000; /* Turn off all comparators */
    CM2CON        = 0b00000000;
    CVRCON        = 0b00000000;

    LATA          = 0;
    LATC          = 0;
    /*
     * PORTB used to debug deep sleep code so set the output latch 
     * from the 'frozen' state before we release the hold.
     */
    LATB          = PORTB;      /*  */
    
    TRISA         = 0b11111111;
    TRISB         = 0b11110001; /* RB1, RB2 & RB3 used to debug deep sleep code */
    TRISC         = 0b11111111;
    INTCON2      |= 0b10000000; /* disable PORTB pull-ups           */

    /*
     * Release deep sleep freeze of GPIO pins
     */
    DSCONLbits.RELEASE = 0;
    LATBbits.LATB1 = 1;     /* Assert RB1 to show we started the init */

/* UnLock Registers */
    PPSCONbits.IOLOCK = 0;  /* Trick compiler to load PPSCON bank early */
    EECON2 = 0x55;
    EECON2 = 0xAA;
    PPSCONbits.IOLOCK = 0;  /* This should be a sinlge instruction, check generated code */
/* Unlock ends */
    
    /* map inputs */
    RPINR1  = eRPI_NONE;    /* INT1         */
    RPINR2  = eRPI_NONE;    /* INT2         */
    RPINR3  = eRPI_NONE;    /* INT3         */
    RPINR4  = eRPI_NONE;    /* T0CLKI       */
    RPINR6  = eRPI_NONE;    /* T3CKI        */
    RPINR7  = eRPI_NONE;    /* CCP1         */
    RPINR8  = eRPI_NONE;    /* CCP2         */
    RPINR12 = eRPI_NONE;    /* T1G          */
    RPINR13 = eRPI_NONE;    /* T3G          */
    RPINR16 = eRPI_NONE;    /* RX2          */
    RPINR17 = eRPI_NONE;    /* CK2          */
    RPINR21 = eRPI_NONE;    /* SDI2         */
    RPINR22 = eRPI_NONE;    /* SCK2IN       */
    RPINR23 = eRPI_NONE;    /* SS2IN        */
    RPINR24 = eRPI_NONE;    /* FLT0         */
    
    /* map outputs */
    RPOR0   = eRPO_NONE;    /* pin RA0      */
    RPOR1   = eRPO_NONE;    /* pin RA1      */
    RPOR2   = eRPO_NONE;    /* pin RA5      */
    RPOR3   = eRPO_NONE;    /* pin RB0      */
    RPOR4   = eRPO_NONE;    /* pin RB1      */
    RPOR5   = eRPO_NONE;    /* pin RB2 REFO */
    RPOR6   = eRPO_NONE;    /* pin RB3      */
    RPOR7   = eRPO_NONE;    /* pin RB4      */
    RPOR8   = eRPO_NONE;    /* pin RB5      */
    RPOR9   = eRPO_NONE;    /* pin RB6 PGC  */
    RPOR10  = eRPO_NONE;    /* pin RB7 PGD  */
    RPOR11  = eRPO_NONE;    /* pin RC0      */
    RPOR12  = eRPO_NONE;    /* pin RC1      */
    RPOR13  = eRPO_NONE;    /* pin RC2      */
    RPOR17  = eRPO_NONE;    /* pin RC6 TX1  */
    RPOR18  = eRPO_NONE;    /* pin RC7 RX1  */
    RPOR19  = eRPO_NONE;    /* pin RD2      */
    RPOR20  = eRPO_NONE;    /* pin RD3      */
    RPOR21  = eRPO_NONE;    /* pin RD4      */
    RPOR22  = eRPO_NONE;    /* pin RD5      */
    RPOR23  = eRPO_NONE;    /* pin RD6      */
    RPOR24  = eRPO_NONE;    /* pin RD7      */
    
/* Lock Registers */
    PPSCONbits.IOLOCK = 0;  /* Trick compiler to load PPSCON bank early */
    EECON2 = 0x55;
    EECON2 = 0xAA;
    PPSCONbits.IOLOCK = 1;  /* This should be a sinlge instruction, check generated code */
/* Lock Registers ends */

    /*
     * Decide if we can start up the high speed system oscillator
     * 
     * But this choice depends on the hardware implementation.
     * 
     * This code assumes that this is always wanted.
     */
    {
        /* put code here */
    }
    /*
     * Look at flags to see what kind of start up this is
     */
    if(WDTCONbits.DS) /* Deep sleep wake up */
    {
        if(DSWAKEHbits.DSINT0)
        {
            Result = eDSWINT0;      /* INT0 wake from deep sleep */
        }
        else if(DSWAKELbits.DSWDT)
        {
            Result = eDSWDTO;       /* Timeout wake from deep sleep */
        }
        else if(DSWAKELbits.DSPOR)
        {
            Result = eDSPOR;        /* MCLR wake from deep sleep */
            RCON |= 0b00111111;
            LATB   = 0;
        }
    }
    else              /* Other class of wake up */
    {
        if(RCONbits.NOT_PD == 0) /* Power on reset */
        {
            Result = ePOR;          /* Power On reset */
            RCON |= 0b00111111;
            LATB   = 0;
        }
        else if(RCONbits.NOT_TO)
        {
            Result = eWDTO;         /* Watch Dog Timeout reset */
            RCONbits.NOT_TO = 1;
        }
    }

    LATBbits.LATB1 = 0;     /* Deassert RB1 to show we completed the init */
    return Result;
}   
/*  
** Application loop
*/  
void main(void)
{   
    eWakeReason ResetType;
    
    /* Initialize this PIC */    
    ResetType = PIC_Init();
    
    switch (ResetType)
    {
        case ePOR:              /* Power on reset, hello there */
            break;
        case eDSWDTO:           /* DSWDT timeout wake from deep sleep */
            LATBbits.LATB2 ^= 1; /* toggle RB2 on each timeout wake from deep sleep */
            break;
        case eDSWINT0:          /* DSINT0 wake from deep sleep */  
            LATBbits.LATB3 ^= 1; /* toggle RB3 on each INT0 wake from deep sleep */
            break;
        case eDSPOR:            /* MCLR wake from deep sleep */
            break;
        case eWDTO:             /* WDT reset, never in deep sleep */
            break;
        default:                /*  */
            break;
    };
    
    /*
     * Warning: Simulator does not simulate deep sleep very well
     */
    /* enter deep sleep code */
    INTCON  &= ~0xF8;             /* Disable all interrupt sources */
    INTCON3 &= ~0x38;
    PIE1 = 0;
    PIE2 = 0;
    PIE3 = 0;

    TRISBbits.TRISB0 = 1;   /* Make RB0/INT0 an input */
    ANCON1bits.PCFG8 = 1;   /* Make RB0/INT0 a digital input */
    OSCCONbits.IDLEN = 0;
    WDTCONbits.SWDTEN = 1;  /* Enable the regular Watch Dog Time out too */
    WDTCONbits.REGSLP = 1;
    INTCON2bits.INTEDG0 = 0; /* Select HIGH to LOW edge for interrupt */
    INTCONbits.INT0IF = 0;  /* Clear the INT0 reauest flag */
    INTCONbits.INT0IE = 1;  /* Enable an INT0 assert to wake from sleep */
    DSCONHbits.DSEN = 1;
    Nop();
    Sleep();
    
    /*
     * If we get to deep sleep the only way out
     * is through the reset vector.
     * 
     * When we do not get to deep sleep we toggle RB1 fast and hang
     * until the regular sleep mode WDT causes a reset.
     */
    for(;;)
    {
        LATBbits.LATB1 ^= 1; /* Toggle RB1 and hang to show we failed to enter deep sleep */
    }
}   
