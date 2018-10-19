/*
 * file: main.c
 * target: PIC12F508
 * IDE: MPLABX v4.05
 * compiler: XC8 v1.45 (free mode)
 *
 * Description:
 *
 *  This application usea Charlieplexing to turn on 1 of 6 LEDs attached 
 *  to GPIO pins GP2, GP4 & GP5 in all possible combinations.
 *  
 *
 *                       PIC12F508
 *              +-----------:_:-----------+
 *       5v0 -> : 1 VDD             VSS 8 : <- GND
 *           <> : 2 GP5         PGD/GP0 7 : <> ICD_PGD
 *           <> : 3 GP4         PGC/GP1 6 : <> ICD_PGC
 *  ICD_MCLR -> : 4 GP3/MCLR        GP2 5 : <> 
 *              +-------------------------+
 *                         DIP-8
 *
 *  PIKkit1
 *   J3        DIP-8   DIP-14
 *    1 - RA5   2       2
 *    2 - RA4   3       3
 *    3 - RA3   4       4
 *    4 - RC5           5
 *    5 - RC4           6  
 *    6 - RC3           7
 *    7 - RA0   7      13
 *    8 - RA1   6      12
 *    9 - RA2   5      11
 *   10 - RC0          10
 *   11 - RC1           9
 *   12 - RC2           8
 *   +5 -       1       1
 *  GND -       8      14
 * 
 * Notes:
 *  Charlieplexing, see https://en.wikipedia.org/wiki/Charlieplexing
 */
/*
 * PIC12F508 specific configuration words
 */
#pragma config OSC = IntRC      // Oscillator Selection bits (internal RC oscillator)
#pragma config WDT = OFF        // Watchdog Timer Enable bit (WDT disabled)
#pragma config CP = OFF         // Code Protection bit (Code protection off)
#pragma config MCLRE = ON       // GP3/MCLR Pin Function Select bit (GP3/MCLR pin function is MCLR)

#include <xc.h>
/*
 * Application specific constants
 */
#define FSYS (4000000L)
#define FCYC (FSYS/4L)
#define TIMER0_COUNTS_UNTIL_ASSERT 128L
#define TIMER0_PRESCALE 64L
#define MAX_LED_STATES 6
/*
 * Global data
 */
unsigned char gLEDs;
unsigned char gTRISGPIO;
unsigned char gTMR0_MSB;
unsigned char gPause;
/*
** LED_refresh
**
** This function must be called regularly from the application loop. 
**
** We use 1 of 6 timing to multiplex (charlieplex) and drive six LEDs
** on the PICkit1 Flash Starter Kit. This rate is fast enough so
** all LED can appear to be on at the same time.
**
** See the PICkit1 Flash Starter Kit User Guide (40051D.pdf) 
** for more information on how the LEDs are connected.
**
*/
void LED_refresh(void)
{
    static unsigned char State = MAX_LED_STATES;

    unsigned char OutBits, HighBits;

    OutBits  =  0b00000000;
    HighBits =  0b00000000;

    switch (--State)
    {
    case 5:
        if (gLEDs & 0x20)
        {
            HighBits |= (1 << 2); /* enable LED5 */
            OutBits = ~0b00100100;
        }
        break;

    case 4:
        if (gLEDs & 0x10)
        {
            HighBits |= (1 << 5); /* enable LED4 */
            OutBits = ~0b00100100;
        }
        break;

    case 3:
        if (gLEDs & 0x08)
        {
            HighBits |= (1 << 2); /* enable LED3 */
            OutBits = ~0b00010100;
        }
        break;

    case 2:
        if (gLEDs & 0x04)
        {
            HighBits |= (1 << 4); /* enable LED2 */
            OutBits = ~0b00010100;
        }
        break;

    case 1:
        if (gLEDs & 0x02)
        {
            HighBits |= (1 << 5); /* enable LED1 */
            OutBits = ~0b00110000;
        }
        break;

    default:
        if (gLEDs & 0x01)
        {
            HighBits |= (1 << 4); /* enable LED0 */
            OutBits = ~0b00110000;
        }
        State = MAX_LED_STATES;
    }

    gTRISGPIO |= 0b00110100;       /* turn off all LED output drivers */
    TRISGPIO   = gTRISGPIO;
    if (OutBits)
    {
        GPIO      &= OutBits;      /* set both LED drivers to low */
        gTRISGPIO &= OutBits;      /* enable LED ouput drivers */
        TRISGPIO   = gTRISGPIO;
        GPIO      |= HighBits;     /* turn on just one of the two LEDs  */
    }
}

/*
 * Initialize PIC hardware for this application
 */
void PIC_Init( void )
{
    OPTION = 0b11010101; /* TIMER0 prescale 1:64, clock source FCYC */
    /*
     * Wait for about 1/2 second after reset to 
     * give MPLAB/ICD time to connect.
     */
    gTMR0_MSB = TMR0;
    for( gPause = (FCYC/(2L * TIMER0_COUNTS_UNTIL_ASSERT * TIMER0_PRESCALE)); gPause != 0; )
    {
        CLRWDT();
        if((TMR0 ^ gTMR0_MSB ) & 0x80)
        {
            gTMR0_MSB ^= 0x80;
            gPause -= 1;
        }
    }
    /*
     * PIC12F508 specific initialization
     */
    GPIO      = 0;
    gTRISGPIO = 0b11111111;
    TRISGPIO  = gTRISGPIO;
}
/*
 * Application
 */
#define LED_STEP (64u)
void main(void) 
{
    PIC_Init();
    /*
     * Process loop
     */
    gTMR0_MSB = TMR0;
    gPause = LED_STEP;
    for(;;)
    {
        LED_refresh();
        if((TMR0 ^ gTMR0_MSB ) & 0x80)
        {
            gTMR0_MSB ^= 0x80;
            if(--gPause == 0)
            {
                gLEDs <<= 1;
                gLEDs  &= 0x3F;
                if(!gLEDs) 
                {
                    gLEDs = 1;
                }
                gPause = LED_STEP;
            }
        }
    }
}
