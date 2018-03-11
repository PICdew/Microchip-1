/*
 * File:   lcd.h
 * Author: 
 * Target: PIC18F24K20, PIC18F2520
 *
 */
#ifndef LCD_H
#define LCD_H

/* Define the LCD interface and character size */
#define LCD_FORMAT (FOUR_BIT & LINES_5X7)

/* Define the LCD port pins */

#define E_PIN               LATAbits.LATA5
#define RW_PIN              LATAbits.LATA4
#define RS_PIN              LATAbits.LATA3
#define LCD_DATA_BITS       (0xF0)
#define LCD_PORT_IN         PORTC
#define LCD_PORT_OUT        LATC


#define E_PIN_DIR           TRISAbits.TRISA5
#define RW_PIN_DIR          TRISAbits.TRISA4
#define RS_PIN_DIR          TRISAbits.TRISA3
#define LCD_PORT_DIR        TRISC

/* Clear display command */
#define CLEAR_DISPLAY 0b00000001u

/* Return home command */
#define RETURN_HOME 0b00000010u

/* Display ON/OFF Control defines */
#define DON         0b00001111u   /* Display on      */
#define DOFF        0b00001011u   /* Display off     */
#define CURSOR_ON   0b00001111u   /* Cursor on       */
#define CURSOR_OFF  0b00001101u   /* Cursor off      */
#define BLINK_ON    0b00001111u   /* Cursor Blink    */
#define BLINK_OFF   0b00001110u   /* Cursor No Blink */

/* Cursor or Display Shift defines */
#define SHIFT_CUR_LEFT    0b00010011u   /* Cursor shifts to the left   */
#define SHIFT_CUR_RIGHT   0b00010111u   /* Cursor shifts to the right  */
#define SHIFT_DISP_LEFT   0b00011011u   /* Display shifts to the left  */
#define SHIFT_DISP_RIGHT  0b00011111u   /* Display shifts to the right */

/* Function Set defines */
#define FOUR_BIT   0b00101111u   /* 4-bit Interface               */
#define EIGHT_BIT  0b00111111u   /* 8-bit Interface               */
#define LINE_5X7   0b00110011u   /* 5x7 characters, single line   */
#define LINE_5X10  0b00110111u   /* 5x10 characters               */
#define LINES_5X7  0b00111011u   /* 5x7 characters, multiple line */

/* Start address of each line */
#define LINE_ONE    0x00u
#define LINE_TWO    0x40u

void LCD_Init(void);
void LCD_SetCGRamAddr(unsigned char data);
void LCD_SetDDRamAddr(unsigned char data);
void LCD_WriteCmd(unsigned char data);
void LCD_WriteData(unsigned char data);
void LCD_WriteConstString(const unsigned char * prString);
void LCD_WriteString(unsigned char * pString);

#endif
