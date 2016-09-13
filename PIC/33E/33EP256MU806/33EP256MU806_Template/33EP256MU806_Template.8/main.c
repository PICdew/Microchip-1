/*
 * file: main.c
 * target: dsPIC33EP256MU806
 * IDE: MPLAB v8.92
 * Compiler: XC16 v1.26
 * 
 * Description:
 *
 *
 *
 *
 */

#pragma config GWRP = OFF, GSS = OFF, GSSK = OFF
#pragma config FNOSC = FRC, IESO = OFF 
#pragma config POSCMD = NONE, OSCIOFNC = OFF, IOL1WAY = OFF, FCKSM = CSECMD
#pragma config WDTPOST = PS32768, WDTPRE = PR128, PLLKEN = ON, WINDIS = OFF, FWDTEN = OFF
#pragma config FPWRT = PWR128, BOREN = OFF, ALTI2C1 = OFF
#pragma config ICS = PGD1, JTAGEN = OFF, RSTPRI = PF
#pragma config AWRP = OFF, APL = OFF, APLK = OFF


#include <xc.h>

/* Setup the clock to run at about 60 MIPS */
#define FOSC  (7370000L)    /* nominal fast RC frequency */
#define PLL_N1 (2L)         /* PLLPRE  CLKDIV<4:0> range 2 to 33 */
#define PLL_M  (65L)        /* PLLDIV  PLLFBD<8:0> range 2 to 513 */
#define PLL_N2 (2L)         /* PLLPOST CLKDIV<7:6> range 2, 4 or 8 */
#define FSYS (FOSC*PLL_M/(PLL_N1*PLL_N2))
#define FCYC (FSYS/2L)
/*
 * Gloabl constant data
 */
const unsigned long gInstructionCyclesPerSecond = FCYC;
/*
 * Initialize this PIC
 */
void PIC_Init( void )
{
    /*
    ** Disable all interrupt sources
    */
    __builtin_disi(0x3FFF); /* disable interrupts for 16383 cycles */
    IEC0 = 0;
    IEC1 = 0;
    IEC2 = 0;
    IEC3 = 0;
    IEC4 = 0;
    IEC5 = 0;
    IEC6 = 0;
    IEC8 = 0;
    __builtin_disi(0x0000); /* enable interrupts */

    /* Configure PLL prescaler, PLL postscaler, PLL divisor */
    PLLFBD=PLL_M-2; /* M=65 */
#if   PLL_N2==2
    CLKDIVbits.PLLPOST=0; /* N2=2 */
#elif PLL_N2==4
    CLKDIVbits.PLLPOST=1; /* N2=4 */
#elif PLL_N2==8
    CLKDIVbits.PLLPOST=3; /* N2=8 */
#else
#error invalid PLL_N2 paramenter
#endif
    CLKDIVbits.PLLPRE=PLL_N1-2; /* N1=2 */

    /* Initiate Clock Switch to FRC oscillator with PLL (NOSC=0b001) */
    __builtin_write_OSCCONH(0x01);
    __builtin_write_OSCCONL(OSCCON | 0x01);
    /* Wait for Clock switch to occur */
    while (OSCCONbits.COSC!= 0b001);
    /* Wait for PLL to lock */
    while (OSCCONbits.LOCK!= 1);

    /* make all inputs digital I/O */
    ANSELB = 0x00;
    ANSELC = 0x00;
    ANSELD = 0x00;
    ANSELE = 0x00;
    ANSELG = 0x00;

}
/*
 * Main process loop
 */
int main( void )
{
    PIC_Init();
    
    for(;;)
    {
        /* process loop */
    }
    return 0;
}
