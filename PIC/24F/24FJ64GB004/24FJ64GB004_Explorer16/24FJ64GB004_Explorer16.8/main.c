/*
 * File: main.c
 * Target: PIC24FJ64GB004
 * IDE: MPLAB v8.92
 * Compiler: XC16 v1.26
 * Target hardware: 44-pin PIM in the Explorer16
 *
 * Description:
 *  This is a mostly brain dead demo of using the UART on the
 *  Explorer16 with the PIC24FJ64GB004 44-pin PIM.
 *
 * Notes:
 *
 *                                                   PIC24FJ64GB004
 *               +------------+              +-----------+                   +-----------+                  +-----------+
 * LCD_D3  <>  1 : RB9/PMPD3  : LED_D3 <> 12 : RA10      :      LCD_D2 <> 23 : RB2/PMPD2 :   Y1-32KHZ <> 34 : RA4/SOSCO :
 * LED_D10 <>  2 : RC6/RP22   : LED_D4 <> 13 : RA7       :      LCD_E  <> 24 : RB3/PMPWR :     LED_D7 <> 35 : RA9       :
 * LCD_RS  <>  3 : RC7/PMPA0  :  U2CTS <> 14 : RB14/RP14 :          J2 <> 25 : RC0/AN6   :       U2RX <> 36 : RC3/RP19  :
 *   SCK2  <>  4 : RC8/RP24   :   SCK1 <> 15 : RB15/RP15 :          J1 <> 26 : RC1/AN7   :       SDI2 <> 37 : RC4/RP20  :
 *   U2TX  <>  5 : RC9/RP25   :    GND -> 16 : AVSS      :        INT1 <> 27 : RC2/RP18  :       SDO2 <> 38 : RC5/RP21  :
 *    GND  <>  6 : DISVREG    :    PWR -> 17 : AVDD      :         PWR -> 28 : VDD       :        GND -> 39 : VSS       :
 *   10uf  ->  7 : VCAP       :   MCLR -> 18 : MCLR      :         GND -> 29 : VSS       :        PWR -> 40 : VDD       :
 *    PGD  <>  8 : RB10/PGD2  : LCD_D7 <> 19 : RA0/PMPD7 :        OSCI <> 30 : RA2/OSCI  : RG14/USBID <> 41 : RB5       :
 *    PGC  <>  9 : RB11/PGC2  : LCD_D6 <> 20 : RA1/PMPD6 :        OSCO <> 31 : RA3/OSCO  : RG15/VBUS  -> 42 : VBUS      :
 *    PWR  -> 10 : VUSB       : LCD_D0 <> 21 : RB0/PMPD0 :          J3 <> 32 : RA8       :     LCD_D5 <> 43 : RB7/PMPD5 :
 * LCD_RW  <> 11 : RB13/PMPRD : LCD_D1 <> 22 : RB1/PMPD1 :    Y1-32KHZ <> 33 : RB4/SOSCI :     LCD_D4 <> 44 : RB8/PMPD4 :
 *               +------------+              +-----------+                   +-----------+                  +-----------+
 *                                                     TQFP-44
 *    Default       Alternale     Open
 * J1 2-3=POT     , 1-2=PICTail+, SDI1 (RP17)
 * J2 2-3=TEMP    , 1-2=PICTail+, SDO1 (RP16)
 * J3 1-2=EEPROMn , 2-3=PICTail+, LED_D8
 *
 */
/*
 * Configuration words
 */
#pragma config JTAGEN=OFF, GCP=OFF, GWRP=OFF, ICS=PGx2, FWDTEN=OFF, WINDIS=OFF, FWPSA=PR32, WDTPS=PS8192
#pragma config IESO=OFF, FNOSC=FRC, POSCMOD=NONE, PLL96MHZ=OFF, PLLDIV=DIV2, FCKSM=CSECMD, OSCIOFNC=ON
#pragma config I2C1SEL=PRI, WPEND=WPENDMEM, WPCFG=WPCFGDIS, WPDIS=WPDIS, WUTSEL=LEG, SOSCSEL=IO, WPFP=WPFP63
#pragma config IOL1WAY=OFF, DSWDTEN=OFF, DSBOREN=OFF, RTCOSC=LPRC, DSWDTOSC=LPRC, DSWDTPS=DSWDTPS6
/*
 * Target specific definitions
 */
#include <xc.h>
/*
 * Standard library definitions
 */
#include <stdio.h>
/*
 * Application specific definitions
 */
#define FOSC (8000000UL)
#define FCYC (FOSC/2UL)
/*
 * Definition for UART setup
 */
#define UARTNUM     2               /* Which device UART to use */

#define BAUDRATE    9600L           /* Baud rate */
#define USE_HI_SPEED_BRG            /* Use BRGH=1, UART high speed mode */

/* UART Baud Rate Calculation */
#ifdef USE_HI_SPEED_BRG
    #define BRG_DIV 4L
#else
    #define BRG_DIV 16L
#endif

#define BAUDRATEREG    (((FCYC + (BRG_DIV * BAUDRATE / 2L)) / (BRG_DIV * BAUDRATE)) - 1L)
#define BAUD_ACTUAL    (FCYC/BRG_DIV/(BAUDRATEREG+1))

#define BAUD_ERROR          ((BAUD_ACTUAL > BAUDRATE) ? BAUD_ACTUAL-BAUDRATE : BAUDRATE-BAUD_ACTUAL)
#define BAUD_ERROR_PRECENT  ((BAUD_ERROR*100L+BAUDRATE/2L)/BAUDRATE)

#if (BAUD_ERROR_PRECENT > 3)
    #error "UART frequency error is worse than 3%"
#elif (BAUD_ERROR_PRECENT > 2)
    #warning "UART frequency error is worse than 2%"
#endif

/* UART Configuration */
#define UARTREG2(a,b)     U##a##b
#define UARTREG(a,b)    UARTREG2(a,b)

#define UxMODE      UARTREG(UARTNUM,MODE)
#define UxBRG       UARTREG(UARTNUM,BRG)
#define UxSTA       UARTREG(UARTNUM,STA)
#define UxRXREG     UARTREG(UARTNUM,RXREG)
#define UxTXREG     UARTREG(UARTNUM,TXREG)
#define UxMODEbits  UARTREG(UARTNUM,MODEbits)
#define UxSTAbits   UARTREG(UARTNUM,STAbits)
#define UxTX_IO     UARTREG(UARTNUM,TX_IO)

const int __C30_UART = UARTNUM;
/*
 * Initialize this PIC hardware
 */
/* define map input pin numbers */
enum
{
    RPI0  = 0,      /* pin RB00 PGD1 */
    RPI1,           /* pin RB01 PGC1 */
    RPI2,           /* pin RB02 */
    RPI3,           /* pin RB03 */
    RPI4,           /* pin RB04 */
    RPI5,           /* pin RA00 */
    RPI6,           /* pin RA01 */
    RPI7,           /* pin RB07 INT0/CN23 */
    RPI8,           /* pin RB08 */
    RPI9,           /* pin RB09 */
    RPI10,          /* pin RB10 */
    RPI11,          /* pin RB11 */
    RPI13 = 13,     /* pin RB13 (REFO output)*/
    RPI14,          /* pin RB14 */
    RPI15,          /* pin RB15 */
    RPI16,          /* pin RC00 */
    RPI17,          /* pin RC01 */
    RPI18,          /* pin RC02 */
    RPI19,          /* pin RC03 */
    RPI20,          /* pin RC04 */
    RPI21,          /* pin RC05 */
    RPI22,          /* pin RC06 */
    RPI23,          /* pin RC07 */
    RPI24,          /* pin RC08 */
    RPI25,          /* pin RC09 */
    RPI_NONE = 0x1f
};

/* define map output function numbers */
enum
{
    RPO_NONE = 0,
    RPO_C1OUT,
    RPO_C2OUT,
    RPO_U1TX,
    RPO_U1RTS,
    RPO_U2TX,
    RPO_U2RTS,
    RPO_SDO1,
    RPO_SCK1OUT,
    RPO_SS1OUT,
    RPO_SDO2,
    RPO_SCK2OUT,
    RPO_SS2OUT,
    RPO_OC1,
    RPO_OC2,
    RPO_OC3,
    RPO_OC4,
    RPO_OC5,
    RPO_CTPLS=29,
    RPO_C3OUT
};

void Init_PIC(void)
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
    __builtin_disi(0x0000); /* enable interrupts */
    _NSTDIS = 1;    /* disable interrupt nesting */
    /*
     * Set system oscillator to 8MHz using the internal FRC.
     */
    CLKDIV = 0x0000;
    if(OSCCONbits.CLKLOCK == 0) /* if primary oscillator switching is unlocked */
    {
        __builtin_write_OSCCONH(0x01); /* select FRCPLL as primary clock source */
        __builtin_write_OSCCONL(OSCCON | (1<<_OSCCON_OSWEN_POSITION));
        /* wait for clock to switch */
        for(ClockSwitchTimeout = 60000; ClockSwitchTimeout; ClockSwitchTimeout--)
        {
            if(!OSCCONbits.OSWEN) break;
        }
        /* primary oscillator is now 8MHz for a 4MIPS instruction cycle */
    }
    /*
     * Make all pins digital GPIO
     */
    AD1PCFG = 0xffff; /* Set for digital I/O */

    /* Unlock Registers */
    __builtin_write_OSCCONL(OSCCON & 0xBF);

    /* unmap all inputs */

    _INT1R  = RPI_NONE; /* External Interrupt 1    */
    _INT2R  = RPI_NONE; /* External Interrupt 2    */
    _IC1R   = RPI_NONE; /* Input Capture 1         */
    _IC2R   = RPI_NONE; /* Input Capture 2         */
    _IC3R   = RPI_NONE; /* Input Capture 3         */
    _IC4R   = RPI_NONE; /* Input Capture 4         */
    _IC5R   = RPI_NONE; /* Input Capture 5         */
    _OCFAR  = RPI_NONE; /* Output Compare Fault A  */
    _OCFBR  = RPI_NONE; /* Output Compare Fault B  */
    _SCK1R  = RPI_NONE; /* SPI1 Clock Input        */
    _SDI1R  = RPI_NONE; /* SPI1 Data Input         */
    _SS1R   = RPI_NONE; /* SPI1 Slave Select Input */
    _SCK2R  = RPI_NONE; /* SPI2 Clock Input        */
    _SDI2R  = RPI_NONE; /* SPI2 Data Input         */
    _SS2R   = RPI_NONE; /* SPI2 Slave Select Input */
    _T2CKR  = RPI_NONE; /* Timer2 External Clock   */
    _T3CKR  = RPI_NONE; /* Timer3 External Clock   */
    _T4CKR  = RPI_NONE; /* Timer4 External Clock   */
    _T5CKR  = RPI_NONE; /* Timer5 External Clock   */
    _U1CTSR = RPI_NONE; /* UART1 Clear To Send     */
    _U1RXR  = RPI_NONE; /* UART1 Receive           */
    _U2CTSR = RPI_NONE; /* UART2 Clear To Send     */
    _U2RXR  = RPI19;    /* UART2 Receive           */ /* pin RC03 */

    /* unmap all outputs */
    _RP0R   = RPO_NONE; /* pin RB00 PGD1 */
    _RP1R   = RPO_NONE; /* pin RB01 PGC1 */
    _RP2R   = RPO_NONE; /* pin RB02 */
    _RP3R   = RPO_NONE; /* pin RB03 */
    _RP4R   = RPO_NONE; /* pin RB04 */
    _RP5R   = RPO_NONE; /* pin RA00 */
    _RP6R   = RPO_NONE; /* pin RA01 */
    _RP7R   = RPO_NONE; /* pin RB07 INT0/CN23 */
    _RP8R   = RPO_NONE; /* pin RB08 */
    _RP9R   = RPO_NONE; /* pin RB09 */
    _RP10R  = RPO_NONE; /* pin RB10 */
    _RP11R  = RPO_NONE; /* pin RB11 */
    _RP13R  = RPO_NONE; /* pin RB13 (REFO output)*/
    _RP14R  = RPO_NONE; /* pin RB14 */
    _RP15R  = RPO_NONE; /* pin RB15 */
    _RP16R  = RPO_NONE; /* pin RC00 */
    _RP17R  = RPO_NONE; /* pin RC01 */
    _RP18R  = RPO_NONE; /* pin RC02 */
    _RP19R  = RPO_NONE; /* pin RC03 */
    _RP20R  = RPO_NONE; /* pin RC04 */
    _RP21R  = RPO_NONE; /* pin RC05 */
    _RP22R  = RPO_NONE; /* pin RC06 */
    _RP23R  = RPO_NONE; /* pin RC07 */
    _RP24R  = RPO_NONE; /* pin RC08 */
    _RP25R  = RPO_U2TX; /* pin RC09 */ /* UART2 Transmit          */

    /* Lock Registers */
    __builtin_write_OSCCONL(OSCCON | 0x40);
}
/*
 * SETUP UART: No parity, one stop bit, polled
 */
void Init_UART(void)
{
    UxMODE = 0;             /* reset UART */
    UxSTA  = 0;
    UxMODEbits.UARTEN = 1;  /* enable  UART */
    UxBRG = BAUDRATEREG;    /* set baud rate */

#ifdef USE_HI_SPEED_BRG
    UxMODEbits.BRGH = 1;    /* use high speed mode */
#else
    UxMODEbits.BRGH = 0;    /* use low speed mode */
#endif

    UxSTAbits.UTXEN;        /* Enable TX */
}
/* warning non-portable function */
/*
 * This function waits for the at least the 
 * specified number milliseconds then returns.
 */
void delay(unsigned long wait_ms)
{
    while(wait_ms)
    {
        asm("    repeat  %0 \n" 
            "    clrwdt     \n"
            : /* no outputs */ 
            : "r" (FCYC/1000-1)
            ); 

        wait_ms = wait_ms - 1;
    }
}    
/*
 * Main application
 */
int main(void)
{
    /*
     * Setup hardware
     */
    Init_PIC();
    Init_UART();
    /*
     * Wait 20 milliseconds for UART TXD output to be stable at a stop bit.
     */
    delay(20);    
    /*
     * Show the world we are ready
     */
    printf("Hello world.\r\n");
    /*
     * Application process loop
     */
    for(;;)
    {
        if(UxSTAbits.OERR)
        {
            /* Clear overrun error and reset receiver */
            UxSTAbits.OERR = 0;
        }
        else
        {
            /* Echo character to UART */
            if(UxSTAbits.URXDA)
            {
                putchar(UxRXREG);
            }
        }
    }
    return 0;
}
