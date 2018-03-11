/*
 * File:   keypad.h
 * Author: 
 * Target: PIC18F24K20, PIC18F2520
 *
 */
#ifndef KEYPAD_H
#define KEYPAD_H

#define KP_ROW1_IN PORTBbits.RB0
#define KP_ROW2_IN PORTBbits.RB1
#define KP_ROW3_IN PORTBbits.RB2
#define KP_ROW4_IN PORTBbits.RB3
#define KP_COL1_OUT LATBbits.LATB4
#define KP_COL2_OUT LATBbits.LATB5
#define KP_COL3_OUT LATCbits.LATC2
#define KP_COL4_OUT LATCbits.LATC3

#define KP_ROW1_IN_DIR  TRISBbits.TRISB0
#define KP_ROW2_IN_DIR  TRISBbits.TRISB1
#define KP_ROW3_IN_DIR  TRISBbits.TRISB2
#define KP_ROW4_IN_DIR  TRISBbits.TRISB3
#define KP_COL1_OUT_DIR TRISBbits.TRISB4
#define KP_COL2_OUT_DIR TRISBbits.TRISB5
#define KP_COL3_OUT_DIR TRISCbits.TRISC2
#define KP_COL4_OUT_DIR TRISCbits.TRISC3

enum eKeyEvent
{
    eNoEvent = 0,
    eKeyChanged
};

typedef enum eKeyEvent eKeyEvent_t;

typedef struct 
{
    unsigned int ButtonMatrix;
    unsigned int ChangedMask;    
} KeypadEvent_t;

void Keypad_Init(void);
void Keypad_Scan(void);
eKeyEvent_t Keypad_GetEvent(void);
unsigned char Keypad_GetKey(KeypadEvent_t * pKeypadEvent);
unsigned int Keypad_GetSample(void);

#endif
