/*
 * file: main.c
 * target: PIC12F508
 * IDE: MPLABX v4.05
 * compiler: XC8 v1.45 (free mode)
 *
 * Description:
 *
 *  This application uses Charlieplexing to turn on 6 LEDs attached 
 *  to GPIO pins GP2, GP4 & GP5 in all possible combinations.
 *  
 *
 *                       PIC12F508
 *              +-----------:_:-----------+
 *       5v0 -> : 1 VDD             VSS 8 : <- GND
 *      DRV5 <> : 2 GP5         PGD/GP0 7 : <> ICD_PGD
 *      DRV4 <> : 3 GP4         PGC/GP1 6 : <> ICD_PGC
 *  ICD_MCLR -> : 4 GP3/MCLR        GP2 5 : <> DRV2
 *              +-------------------------+
 *                         DIP-8
 *
 *           150 OHM
 *  DRV2 ----/\/\/\-------+-----------+-------------+-----------+
 *                        :           :             :           :
 *                        :           :             :           :
 *                       ---         ---            :           :
 *                 LED0  / \         \ / LED1       :           :
 *                       ---         ---            :           :
 *                        :           :             :           :
 *           150 OHM      :           :            ---         --- 
 *  DRV4 ----/\/\/\-------+-----------+       LED4 / \         \ / LED5
 *                        :           :            ---         --- 
 *                        :           :             :           :
 *                       ---         ---            :           :
 *                 LED2  / \         \ / LED3       :           :
 *                       ---         ---            :           :
 *                        :           :             :           :
 *           150 OHM      :           :             :           :
 *  DRV5 ----/\/\/\-------+-----------+-------------+-----------+
 *  
 *
 * Notes:
 *  Charlieplexing, see https://en.wikipedia.org/wiki/Charlieplexing
 */

/*
 * PIC12F508 specific configuration words
 */
#pragma config OSC = IntRC      /* Oscillator Selection bits (internal RC oscillator) */
#pragma config WDT = OFF        /* Watchdog Timer Enable bit (WDT disabled) */
#pragma config CP = OFF         /* Code Protection bit (Code protection off) */
#pragma config MCLRE = ON       /* GP3/MCLR Pin Function Select bit (GP3/MCLR pin function is MCLR) */
/*
 * Include PIC12F508 specific symbols
 */
#include <xc.h>
/*
 * Application specific constants
 */
#define FSYS (4000000ul)                    /* syetem oscillator frequency in Hz */
#define FCYC (FSYS/4ul)                     /* number of inctruction clocks in one second */
#define TIMER0_COUNTS_UNTIL_ASSERT (128ul)
#define TIMER0_PRESCALE (64ul)
#define MAX_LED_STATES (6)
#define TIMER0_ASSERTS_IN_ONE_SECOND (2ul)
#define POR_DELAY (FCYC/(TIMER0_ASSERTS_IN_ONE_SECOND * TIMER0_COUNTS_UNTIL_ASSERT * TIMER0_PRESCALE))
/*
 * Check that the Power On Reset delay is in range for this implementation.
 */
#if (POR_DELAY >= 256)
#undef POR_DELAY
#define POR_DELAY (255)
#warning POR Delay too long for this implememnattion
#elif (POR_DELAY < 1)
#undef POR_DELAY
#define POR_DELAY (1)
#warning POR Delay too short for this implememnattion
#endif

/*
 * Global data
 */
unsigned char gLEDs;
unsigned char gTRISGPIO;
unsigned char gTMR0_MSB;
unsigned char gPause;
/*
 * LED_refresh
 *
 * This function must be called regularly from the application loop. 
 *
 * We use 1 of 6 timing to multiplex (charlieplex) and drive six LEDs.
 *
 * This function needs to be called often enough so all the LED 
 * can appear to be on at the same time.
 * 
 * Notes:
 *  For base line PICs like the PIC12F508 the TRISGPIO register
 *  cannot be read. To deal with this a shadow register, gTRISGPIO,
 *  is used in this implementation to remember the state of
 *  the GPIO in or out setting.
 *
 */
void LED_refresh(void)
{
    static unsigned char State = MAX_LED_STATES;

    unsigned char OutBits, HighBits;

    CLRWDT();
    OutBits  =  0b00000000;
    HighBits =  0b00000000;

    switch (--State)
    {
    case 5:
        if (gLEDs & 0x20)
        {
            HighBits |= (1 << 2); /* Drive LED5, GP5=L GP2=H */
            OutBits = ~((1<<5)|(1<<2));
        }
        break;

    case 4:
        if (gLEDs & 0x10)
        {
            HighBits |= (1 << 5); /* Drive LED4, GP5=H GP2=L */
            OutBits = ~((1<<5)|(1<<2));
        }
        break;

    case 3:
        if (gLEDs & 0x08)
        {
            HighBits |= (1 << 4); /* Drive LED3, GP5=L GP4=H */
            OutBits = ~((1<<5)|(1<<4));
        }
        break;

    case 2:
        if (gLEDs & 0x04)
        {
            HighBits |= (1 << 5); /* Drive LED2, GP5=H GP4=L */
            OutBits = ~((1<<5)|(1<<4));
        }
        break;
    case 1:
        if (gLEDs & 0x02)
        {
            HighBits |= (1 << 2); /* Drive LED1, GP4=L GP2=H */
            OutBits = ~((1<<4)|(1<<2));
        }
        break;

    default:
        if (gLEDs & 0x01)
        {
            HighBits |= (1 << 4); /* Drive LED0, GP4=H GP2=L */
            OutBits = ~((1<<4)|(1<<2));
        }
        State = MAX_LED_STATES;
    }

    gTRISGPIO |= ((1<<5)|(1<<4)|(1<<2)); /* Turn off all LED output drivers */
    TRISGPIO   = gTRISGPIO;
    if (OutBits)
    {
        GPIO      &= OutBits;      /* Set both LED drivers to low */
        gTRISGPIO &= OutBits;      /* Turn on LED output drivers */
        TRISGPIO   = gTRISGPIO;
        GPIO      |= HighBits;     /* Turn on just one of the two LEDs  */
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
    for( gPause = POR_DELAY; gPause != 0; )
    {
        CLRWDT();
        if((TMR0 ^ gTMR0_MSB ) & 0x80)
        {
            gTMR0_MSB = TMR0;
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
#define LED_STEP_DELAY (64u)
void main(void) 
{
    PIC_Init();
    /*
     * Process loop
     */
    gTMR0_MSB = TMR0;
    gPause = LED_STEP_DELAY;
    for(;;)
    {
        LED_refresh();
        if((TMR0 ^ gTMR0_MSB ) & 0x80)
        {
            gTMR0_MSB = TMR0;
            if(--gPause == 0)
            {
                gLEDs <<= 1;
                gLEDs  &= 0x3F;
                if(!gLEDs) 
                {
                    gLEDs = 1;
                }
                gPause = LED_STEP_DELAY;
            }
        }
    }
}
