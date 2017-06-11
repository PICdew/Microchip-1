/* 
 * File:     buttons.c
 * Target:   PIC16F18877
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.61
 *
 */
#include "init.h"
#include "buttons.h"


static volatile unsigned char ButtonStatus;
static unsigned char ButtonSample;
static unsigned char ButtonStable;
static unsigned char ButtonChange;
static unsigned char ButtonStableCount;
/*
 * Get button status and clear button chnaged flags
 */
unsigned char Buttons_GetStatus( void )
{
    unsigned char Result;
    
    Result = ButtonStatus;
    ButtonStatus &= ~(BUTTON_S2_CHANGE_MASK | BUTTON_S3_CHANGE_MASK);
    return Result;
}
/*
 * Poll button inputs
 * Should be called once per millisecond
 */
unsigned char Buttons_Poll( void )
{
    ButtonStatus = 0;
    /*
     * Sample raw button, 0 = pressed
     */
    ButtonChange = 0;  /* assume all buttons not pressed */
    if(!ButtonS2) ButtonChange |= (unsigned char)BUTTON_S2_STATE_MASK; /* show button pressed */
    if(!ButtonS3) ButtonChange |= (unsigned char)BUTTON_S3_STATE_MASK; /* show button pressed */
    ButtonChange ^= ButtonSample; /* compare with previous sample */
    if( ButtonChange )
    {
        ButtonSample ^= ButtonChange; /* update sample */
        ButtonStableCount = 0;  /* reset debounce counter */
    }
    else
    {
        if (ButtonStableCount != BUTTON_DEBOUNCE_TIME)
        {
            ButtonStableCount++;
        }
        else
        {
            ButtonChange  = ButtonSample;
            ButtonChange ^= ButtonStable;
            ButtonStable ^= ButtonChange;
            ButtonChange  = (unsigned char)(ButtonChange << 4 | ButtonChange >> 4);
            ButtonStatus  = (unsigned char)(ButtonChange | ButtonStable);
        }
    }
    return ButtonStatus;
}
/*
 * Setup PICDEM2 Plus button inputs
 */
void Buttons_Init( void )
{
    ButtonS2_DIR      = 1;  /* make GPIO an input */
    ButtonS3_DIR      = 1;  /* make GPIO an input */
    ButtonStatus      = 0;
    ButtonSample      = 0;
    ButtonStable      = 0;
    ButtonStableCount = 0;
}