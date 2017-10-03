/*
 * File:   keypad.h
 * Author: 
 * Target: PIC16F877A
 *
 */
#ifndef KEYPAD_H
#define KEYPAD_H

#define KP_DEBOUNCE_COUNT (16)

#define KP_ROW1_IN  PORTBbits.RB0
#define KP_ROW2_IN  PORTBbits.RB1
#define KP_ROW3_IN  PORTBbits.RB2
#define KP_ROW4_IN  PORTBbits.RB3
#define KP_COL1_OUT PORTBbits.RB4
#define KP_COL2_OUT PORTBbits.RB5
#define KP_COL3_OUT PORTCbits.RC5
#define KP_COL4_OUT PORTCbits.RC0

#define KP_ROW1_IN_DIR  TRISBbits.TRISB0
#define KP_ROW2_IN_DIR  TRISBbits.TRISB1
#define KP_ROW3_IN_DIR  TRISBbits.TRISB2
#define KP_ROW4_IN_DIR  TRISBbits.TRISB3
#define KP_COL1_OUT_DIR TRISBbits.TRISB4
#define KP_COL2_OUT_DIR TRISBbits.TRISB5
#define KP_COL3_OUT_DIR TRISCbits.TRISC5
#define KP_COL4_OUT_DIR TRISCbits.TRISC0

enum eKeyEvent
{
    eNoEvent = 0,
    eKeyChanged
};

typedef enum eKeyEvent eKeyEvent_t;

struct sKeypadEvent
{
    unsigned int ButtonMatrix;
    unsigned int ChangedMask;    
}

typedef struct sKeypadEvent KeypadEvent_t;

void Keypad_Init(void);
void Keypad_Scan(void);
eKeyEvent_t Keypad_GetEvent(void);
unsigned char Keypad_GetKey(KeypadEvent_t * KeypadEvent);
unsigned int Keypad_GetSample(void);

#endif
