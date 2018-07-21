/*
 * File:   keypad.c
 * Author: 
 *
 * Target: PIC18F24K20, PIC18F2520
 */

#include "init.h"
#include "keypad.h"

static unsigned int  KP_Sample;
static unsigned int  KP_Last;
static unsigned int  KP_Changed;
static unsigned int  KP_Stable;
static unsigned char KP_DebounceCounter;
/*
 * Initialize the GPIO pins used for the 3x4 keypad
 */
void Keypad_Init(void)
{
    KP_ROW1_IN_DIR  = 1;
    KP_ROW2_IN_DIR  = 1;
    KP_ROW3_IN_DIR  = 1;
    KP_ROW4_IN_DIR  = 1;
    KP_COL1_OUT_DIR = 0;
    KP_COL2_OUT_DIR = 0;
    KP_COL3_OUT_DIR = 0;
    KP_COL4_OUT_DIR = 0;
    KP_Last = 0;
    KP_DebounceCounter = 0;
}
/*
 * Called from application loop to sample all keys
 * in the keypad matrix, debounce and update the
 * stable state.
 * 
 * This function should be called every 1 to 2 milliseconds.
 * When called too often the buttons do not debounce correctly.
 * When called too infrequently the buttons seem unresponsive.
 */
void Keypad_Scan(void)
{
    KP_Sample = 0;
    KP_COL1_OUT = 1;
    KP_COL2_OUT = 1;
    KP_COL3_OUT = 1;
    KP_COL4_OUT = 1;
    KP_COL2_OUT_DIR = 1;
    KP_COL3_OUT_DIR = 1;
    KP_COL4_OUT_DIR = 1;
    KP_COL1_OUT_DIR = 0;
    KP_COL1_OUT = 0;
    if (!KP_ROW1_IN) KP_Sample |= 0x0001;
    if (!KP_ROW2_IN) KP_Sample |= 0x0002;
    if (!KP_ROW3_IN) KP_Sample |= 0x0004;
    if (!KP_ROW4_IN) KP_Sample |= 0x0008;
    KP_COL1_OUT = 1;
    KP_COL1_OUT_DIR = 1;
    KP_COL2_OUT_DIR = 0;
    KP_COL2_OUT = 0;
    if (!KP_ROW1_IN) KP_Sample |= 0x0010;
    if (!KP_ROW2_IN) KP_Sample |= 0x0020;
    if (!KP_ROW3_IN) KP_Sample |= 0x0040;
    if (!KP_ROW4_IN) KP_Sample |= 0x0080;
    KP_COL2_OUT = 1;
    KP_COL2_OUT_DIR = 1;
    KP_COL3_OUT_DIR = 0;
    KP_COL3_OUT = 0;
    if (!KP_ROW1_IN) KP_Sample |= 0x0100;
    if (!KP_ROW2_IN) KP_Sample |= 0x0200;
    if (!KP_ROW3_IN) KP_Sample |= 0x0400;
    if (!KP_ROW4_IN) KP_Sample |= 0x0800;
    KP_COL3_OUT_DIR = 1;
    KP_COL3_OUT = 1;
    KP_COL4_OUT_DIR = 0;
    KP_COL4_OUT = 0;
    if (!KP_ROW1_IN) KP_Sample |= 0x1000;
    if (!KP_ROW2_IN) KP_Sample |= 0x2000;
    if (!KP_ROW3_IN) KP_Sample |= 0x4000;
    if (!KP_ROW4_IN) KP_Sample |= 0x8000;
    KP_COL4_OUT = 1;
    KP_COL4_OUT_DIR = 1;

    KP_COL4_OUT = 1;
    KP_COL3_OUT = 1;
    KP_COL2_OUT = 1;
    KP_COL1_OUT = 1;

    KP_COL1_OUT_DIR = 0;
    KP_COL2_OUT_DIR = 0;
    KP_COL3_OUT_DIR = 0;
    KP_COL4_OUT_DIR = 0;
    
    /* check if matrix changed since last scan */
    if ((KP_Sample ^ KP_Last) != 0)
    {
        KP_Last = KP_Sample;
        KP_DebounceCounter = 0;
        return;
    }

    /* check if we have sampled inputs for long enough to debounce */
    if (KP_DebounceCounter < KP_DEBOUNCE_COUNT)
    {
        KP_DebounceCounter++;
        return;
    }

    /* Update the stable output only after pevious stable state has been read */
  if (KP_Sample != KP_Stable)
  {
    if (KP_Changed == 0)
    {
        KP_Changed = KP_Sample ^ KP_Stable;
        KP_Stable = KP_Sample;
    }
  }
}
/*
 * Returns non-zero when a key event occurs.
 * A key event is when one key is pressed or released.
 */
eKeyEvent_t Keypad_GetEvent(void)
{
    eKeyEvent_t Event;
    

    if (KP_Changed == 0)
    {
        Event = eNoEvent;
    }
    else
    {
        Event = eKeyChanged;
    }
    
    return Event;
}
/*
 * Returns ASCII character of keypad event.
 * If more than one key is pressed returns ZERO.
 */
unsigned char Keypad_GetKey(KeypadEvent_t * pKeypadEvent)
{
    unsigned char Key;
    unsigned int ButtonMatrix;
    unsigned int ChangedMask;    

    Key = 0;
    INTCONbits.TMR0IE = 0;  /* disable tick to read keypad sample memory */
    ButtonMatrix = KP_Stable;
    ChangedMask  = KP_Changed;
    /* Tell ISR we have read the current state */
    KP_Changed = 0;
    INTCONbits.TMR0IE = 1;  /* enable tick */

    /* When pointer not NULL return current state of the keypad matrix */
    if (pKeypadEvent != NULL)
    {
        pKeypadEvent->ButtonMatrix = ButtonMatrix;
        pKeypadEvent->ChangedMask  = ChangedMask;
    }
    /* decode key in ASCII */
    if (ChangedMask)
    {
        switch (ButtonMatrix)
        {
        case 0x0001U:
            Key = '1';
            break;
        case 0x0002U:
            Key = '4';
            break;
        case 0x0004U:
            Key = '7';
            break;
        case 0x0008U:
            Key = 'E';
            break;
        case 0x0010U:
            Key = '2';
            break;
        case 0x0020U:
            Key = '5';
            break;
        case 0x0040U:
            Key = '8';
            break;
        case 0x0080U:
            Key = '0';
            break;
        case 0x0100U:
            Key = '3';
            break;
        case 0x0200U:
            Key = '6';
            break;
        case 0x0400U:
            Key = '9';
            break;
        case 0x0800U:
            Key = '.';
            break;
        case 0x1000U:
            Key = 'R';
            break;
        case 0x2000U:
            Key = 'L';
            break;
        case 0x4000U:
            Key = 'U';
            break;
        case 0x8000U:
            Key = 'D';
            break;
        default:
            Key = 0;
            break;
        }
    }
    return Key;
}
