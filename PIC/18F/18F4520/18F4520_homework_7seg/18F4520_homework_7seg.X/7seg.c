/*
 * File:   7seg.c
 * Author: 
 * Target: PIC18F4520
 * Compiler: XC8 v1.38
 * IDE: MPLABX v3.35
 *
 * Pin connections:
 *
 *                        PIC18F4520
 *                 +---------:_:---------+
 *      VPP RE3 -> :  1 MCLR      PGD 40 : <> RB7 PGD  
 *          RA0 <> :  2 AN0       PGC 39 : <> RB6 PGC  SEG-G
 *          RA1 <> :  3 AN1       PGM 38 : <> RB5      SEG-F
 *          RA2 <> :  4 AN2      AN10 37 : <> RB4      SEG-E
 *          RA3 <> :  5 AN3      AN9  36 : <> RB3      SEG-D
 *          RA4 <> :  6          AN8  35 : <> RB2      SEG-C
 *          RA5 <> :  7 AN4      AN11 34 : <> RB1      SEG-B
 *          RE0 <> :  8 AN5      INT0 33 : <> RB0      SEG-A
 *          RE1 <> :  9 AN6           32 : <- VDD
 *          RE2 <> : 10 AN7           31 : <- VSS
 *          VDD -> : 11               30 : <> RD7
 *          VSS -> : 12               29 : <> RD6
 *          RA7 <> : 13 OSC1          28 : <> RD5
 *          RA6 <> : 14 OSC2          27 : <> RD4
 *     SW1  RC0 <> : 15 T1OSO     TXD 26 : <> RC7
 *          RC1 <> : 16 T1OSI     TXD 25 : <> RC6
 *          RC2 <> : 17               24 : <> RC5
 *          RC3 <> : 18 SCL       SDA 23 : <> RC4
 *          RD0 <> : 19               22 : <> RD3
 *          RD1 <> : 20               21 : <> RD2
 *                 +---------------------+
 *                         DIP-40
 *
 * Seven Segment LED mapping:
 *        
 *        __0__  
 *      /      / This is how each bit of PORTB
 *     5      1  is used to drive a 7 segment
 *    /__6__ /   LED display. The display is a
 *   /      /    common cathode device where
 *  4      2     a HIGH, or ONE present on the
 * /__3__ /      output pin lights the segment.
 *               
 *
 * This how HEX codes map to digits 0 to 9:
 *        _____               _____     _____           
 *      /      /         /         /         /  /      /
 *     / 0x3F /    0x06 /    0x5B /    0x4F /  / 0x66 / 
 *    /      /         /   _____ /   _____ /  /_____ /  
 *   /      /         /  /                /         /   
 *  /      /         /  /                /         /    
 * /_____ /         /  /_____     _____ /         /      
 *                                                      
 *        _____     _____     _____     _____     _____ 
 *      /         /                /  /      /  /      /
 *     / 0x6D    / 0x7D      0x07 /  / 0x7F /  / 0x6F / 
 *    /_____    /_____           /  /_____ /  /_____ /  
 *          /  /      /         /  /      /         /   
 *         /  /      /         /  /      /         /    
 *  _____ /  /_____ /         /  /_____ /   _____ /     
 *
 *
 *
 * Description:
 *  
 *  This is one way to complete the generic homework assignments
 *  for many courses on PIC programming. This assignment is typical
 *  are for introductory courses where students are using MPLAB for 
 *  the first time. It is also common for the students to be learning
 *  about the PROTEUS simulation environment as well.
 *
 *  This example has a single digit 7-segment display connected to
 *  PORTB, bits 6 to 0 and a push button switch connected PORTC, bit 0.
 *
 *  The application detects a change of the push button switch then
 *  changes the decimal digit shown on the 7-segment LED in sequence:
 *  0,1,2,3,4,5,6,7,8,9 for each press of the button.
 *
 *  The push button switch is pressed when the input bit is zero and
 *  released when the input is one.
 *
 *  An LED segment is lighted when the output bit is one and is
 *  dark when the output bit is zero,
 *
 *  This implementation uses TIMER0 in 8-bit mode with a 1:8 clock prescale.
 *  Using the internal 8MHz oscillator one millisecond of real time will
 *  have passed when TIMER0 has counted 250 times.
 *
 *  The push button switch input is considered stable when the 
 *  input has not changed for at least 20 of these one millisecond
 *  intervals.
 */

/* PIC18F4520 Configuration Bit Settings */

#pragma config OSC = INTIO67, FCMEN = OFF, IESO = OFF, PWRT = OFF
#pragma config BOREN = SBORDIS, BORV = 3, WDT = OFF, WDTPS = 32768
#pragma config CCP2MX = PORTC, PBADEN = ON, LPT1OSC = OFF, MCLRE = ON
#pragma config STVREN = ON, LVP = OFF, XINST = OFF
#pragma config CP0 = OFF, CP1 = OFF, CP2 = OFF, CP3 = OFF
#pragma config CPB = OFF, CPD = OFF
#pragma config WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF
#pragma config WRTC = OFF, WRTB = OFF, WRTD = OFF
#pragma config EBTR0 = OFF, EBTR1 = OFF, EBTR2 = OFF, EBTR3 = OFF
#pragma config EBTRB = OFF

#include <xc.h>
 
#define _XTAL_FREQ (8000000UL)
#define OSCILLATOR_CYCLES_PER_MILLISECOND (_XTAL_FREQ / 1000UL)
#define OSCILLATOR_CYCLES_PER_INSTRUCTION_CYCLE (4)
#define TMR0_PRESCALE (16)
#define TMR0_COUNTS_PER_MILLISECOND (OSCILLATOR_CYCLES_PER_MILLISECOND / (OSCILLATOR_CYCLES_PER_INSTRUCTION_CYCLE * TMR0_PRESCALE))

#define SW1 PORTCbits.RC0
#define SW1_DIR TRISCbits.TRISC0
#define SW1_INPUT_MASK (1)
#define DEBOUNCE_COUNT (20)
/*
 * Initialize this PIC application hardware
 */
void Init_PIC (void)
{   
    /* disable all interrupts */
    INTCON  = 0x00;
    INTCON3 = 0xC0;
    PIE1 = 0;
    PIE2 = 0;
    RCON = 0; /* disable priority interrupts */
    
    /* set the PIC18F4520 internal oscillator to 8MHZ, no PLL */
    OSCCON = 0x70;          /* select 8MHz oscillator */
    OSCTUNEbits.PLLEN = 0;  /* disable 4x PLL */

    /* set all GPIOs for digital I/O */
    CMCON  = 0x07;
    ADCON1 = 0x0F;
    
    /* make all output low */
    LATA = 0;
    LATB = 0;
    LATC = 0;
    LATD = 0;
    LATE = 0;
    
    /* make all GPIOs outputs */
    TRISA = 0x00;
    TRISB = 0x00;
    TRISC = 0x00;
    TRISD = 0x00;
    TRISE = TRISE & 0xFE;
}   
/*
 * Setup TIMER0 for use as the system clock
 */
void Init_TIMER0 (void)
{   
    T0CON  = 0x00;      /* stop TIMER0 */
    INTCONbits.T0IE = 0;/* disable TIMER0 interrupts */
#if   (TMR0_PRESCALE==1)
    T0CONbits.PSA  = 1; /* set prescaler 1:1 */
#elif (TMR0_PRESCALE==2)
    T0CONbits.PSA  = 0; /* use prescaler */
    T0CONbits.T0PS = 0; /* set prescale as 1:2 */
#elif (TMR0_PRESCALE==4)
    T0CONbits.PSA  = 0; /* use prescaler */
    T0CONbits.T0PS = 1; /* set prescale as 1:4 */
#elif (TMR0_PRESCALE==8)
    T0CONbits.PSA  = 0; /* use prescaler */
    T0CONbits.T0PS = 2; /* set prescale as 1:8 */
#elif (TMR0_PRESCALE==16)
    T0CONbits.PSA  = 0; /* use prescaler */
    T0CONbits.T0PS = 3; /* set prescale as 1:16 */
#elif (TMR0_PRESCALE==32)
    T0CONbits.PSA  = 0; /* use prescaler */
    T0CONbits.T0PS = 4; /* set prescale as 1:32 */
#elif (TMR0_PRESCALE==64)
    T0CONbits.PSA  = 0; /* use prescaler */
    T0CONbits.T0PS = 5; /* set prescale as 1:64 */
#elif (TMR0_PRESCALE==128)
    T0CONbits.PSA  = 0; /* use prescaler */
    T0CONbits.T0PS = 6; /* set prescale as 1:128 */
#elif (TMR0_PRESCALE==256)
    T0CONbits.PSA  = 0; /* use prescaler */
    T0CONbits.T0PS = 7; /* set prescale as 1:256 */
#else
#error Bad TIMER0 prescale selection
#endif
    T0CONbits.T0CS = 0; /* select clock source as FSOC/4 */
    T0CONbits.T08BIT = 1; /* select 8-bit timer mode */
    TMR0L = 0;
    T0CONbits.TMR0ON = 1; /* start timer 0 running */
}   
/*
 * Setup button inputs
 */
void Init_ButtonInput (void)
{   
    SW1_DIR = 1;
}   
/*
 * Setup displau output
 */
void Init_DisplayOutput (void)
{   
    LATB &= ~0x7F;  /* Turn off all LED segmments */
    TRISB &= ~0x7F; /* Make bits that drive the LED segments outputs */
}   
/*
 * Poll TIMER0 to check elapse time for one millisecond tick.
 * 
 * Returns: Zero when less than one millisecond has elapsed
 *          One when one millisecond or more has elapsed
 * 
 * Notes:
 *  This function must be called from just one place in the main 
 *  process loop and must be called at least once per millisecond. 
 * 
 *  This implementation fails when using any of the XC8 _delay() 
 *  functions anywhere else in the application.
 */
unsigned char OneMsTick (void)
{
    static unsigned char T0_Sample = 0;
    unsigned char Delta;
    
    Delta = TMR0L - T0_Sample;
    if (Delta >= TMR0_COUNTS_PER_MILLISECOND)
    {
        T0_Sample += Delta;
        return 1;
    }
    return 0;
}
/*
 * Check for a button event
 * 
 * Returns: ONE when button changed to pressed.
 *          ZERO on all other button states.
 * 
 * Notes:
 *  This function is designed to be callled once per millisecond.
 *  It will return a ONE when the button has changed from the
 *  unpressed to the pressed state and remains pressed for 20
 *  calls to this function.
 * 
 */
unsigned char ButtonEvent (void)
{
    static unsigned char DebounceCount = 0;
    static unsigned char ButtonSample;
    static unsigned char ButtonStable;
           unsigned char ButtonChange;
           unsigned char ButtonInput;
    
    /* assume SW1 is not pressed */
    ButtonInput = 0;
    if (SW1 != 1)
    {
        /* SW1 is pressed */
        ButtonInput = SW1_INPUT_MASK;
    }
    ButtonChange = ButtonSample ^ ButtonInput;
    if (ButtonChange)
    {
        ButtonSample ^= ButtonChange;
        DebounceCount = 0;
    }
    else
    {
        if (DebounceCount >= DEBOUNCE_COUNT)
        {
            ButtonChange = ButtonSample ^ ButtonStable;
            ButtonStable ^= ButtonChange;
            if (ButtonStable & ButtonChange & SW1_INPUT_MASK)
            {
                /* Return a ONE if SW1 changed AND the it changed to pressed */
                return 1;
            }
        }
        else
        {
            DebounceCount++;
        }
    }
    
    return 0;
}
/*
 * Output digits to LED
 */
void DisplayDigit(unsigned char digit)
{
    static const unsigned char SEGMENT_MAP[10]={0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F};

    if (digit < sizeof(SEGMENT_MAP))
    {
        LATB = (LATB & 0x7F) | SEGMENT_MAP[digit];
    }
    else
    {
        LATB &= ~0x7F;
    }
}
/*
 * Power on display test
 * 
 * Lights all segments of the LED for 0.5 seconds
 */
void DisplayTest (void)
{
    unsigned int Display_on = 500;
    
    /* turn on all segments */
    LATB |= 0x7f;
    do
    {
        if(OneMsTick()) Display_on--;
    } while (Display_on);
    /* turn off all segments */
    LATB &= ~0x7f;
}
/*
 * Main application and process loop
 */
void main (void)
{
    unsigned char Digit;
    
    Init_PIC();
    Init_TIMER0();
    Init_ButtonInput();
    Init_DisplayOutput();

    /* Power on LED test */
    DisplayTest();
    
    /* process loop */
    Digit = 0;
    for(;;)
    {
        if (OneMsTick())
        {
            /* poll button status */
            if (ButtonEvent())
            {
                DisplayDigit(Digit);
                Digit++;
                if(Digit > 9)
                {
                    Digit = 0;
                }
            }
        }
    }
}
