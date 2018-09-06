/*
 * File:     main.c
 * Target:   PIC16F18877
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.61
 *
 *                         PIC16F18877
 *                 +----------:_:----------+
 *   S1  VPP ->  1 : RE3/MCLR/VPP  PGD/RB7 : 40 <> PGD
 * R16(0-5V) ->  2 : RA0/AN0       PGC/RB6 : 39 <> PGC
 *           <>  3 : RA1               RB5 : 38 <>
 *           <>  4 : RA2               RB4 : 37 <>
 *           <>  5 : RA3               RB3 : 36 <> LED_D5
 *   S2      ->  6 : RA4               RB2 : 35 <> LED_D4
 *   S3      ->  7 : RA5               RB1 : 34 <> LED_D3
 *           <>  8 : RE0               RB0 : 33 <> LED_D2
 *           <>  9 : RE1               VDD : 32 <- PWR
 *           <> 10 : RE2               VSS : 31 <- GND
 *       PWR -> 11 : VDD               RD7 : 30 -> LCD_ON
 *       GND -> 12 : VSS               RD6 : 29 -> LCD_E
 *      4MHZ -> 13 : RA7/OSC1          RD5 : 28 -> LCD_RW
 *           <- 14 : RA6/OSC2          RD4 : 27 -> LCD_RS
 *           <> 15 : RC0/SOSCO   RX/DT/RC7 : 26 <- RXD
 *           <> 16 : RC1/SOSCI   TX/CK/RC6 : 25 -> TXD
 *    BUZZER <> 17 : RC2/CCP1          RC5 : 24 <>
 *       SCL <> 18 : RC3/SCL       SDA/RC4 : 23 <> SDA
 *    LCD_D4 <> 19 : RD0               RD3 : 22 <> LCD_D7
 *    LCD_D5 <> 20 : RD1               RD2 : 21 <> LCD_D6
 *                 +-----------------------:
 *                          DIP-40
 *
 *   PICDEM 2 Plus:
 *   RD0 <> LCD_D4    Special note that the LCD module on my PICDEM2 PLUS
 *   RD1 <> LCD_D5    is a NOVATEK 7605. In 4-bit mode the NOVATEK 7605 is
 *   RD2 <> LCD_D6    not 100% compatible with the Hitachi HD44780. The
 *   RD3 <> LCD_D7    issue is that in 4-bit mode a status read returns the
 *   RD4 -> LCD_RS    4-bits in an order that is different from the HD44780.
 *   RD5 -> LCD_R/W
 *   RD6 -> LCD_E
 *   RD7 -> LCD_ON
 *
 * WARNING:
 *   This code runs on a modified PICDEM 2 Plus demo board.
 *   The connection for push button S3 has been from RB0 to RA5.
 *
 *
 */

#include <stdlib.h>
#include <string.h>
#include "init.h"
#include "lcd.h"
#include "i2c1.h"
#include "buttons.h"
/*
 * Global Data 
 */
volatile unsigned char gButtonEvent;
volatile unsigned char gTick;

/*
 * Initialize TIMER0
 */
void TIMER0_Init( void )
{
    PIE0bits.TMR0IE = 0;         /* disable TIMER0 interrupts */
    gTick = 0;
    T0CON0 = 0;                  /* stop TIMER0 */
    T0CON1 = 0;
    T0CON1bits.T0CKPS  = 0b0101; /* set prescale at 1:32 */
    T0CON1bits.T0ASYNC = 0;      /* The input to the TMR0 counter is synchronized to FOSC/4 */
    T0CON1bits.T0CS    = 0b010;  /* set clock source to FOSC/4 (8MHz) */
    TMR0H = 250-1;               /* set reload count */
    TMR0L = 0;                   /* start count from zero */
    PIR0bits.TMR0IF = 0;         /* clear interrupt request */
    PIE0bits.TMR0IE = 1;         /* enable TIMER0 interrupt source */
    INTCONbits.PEIE = 1;         /* enable peripheral interrupts */
    T0CON0bits.T0EN = 1;         /* start TIMER0 */
}
/*
 * Display application name and version
 */
void ShowVersion(void)
{
    unsigned char buffer[17];
    
    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteConstString("LCD Test ");

    buffer[0] = 0;
    utoa(buffer,MAJOR_REV,10);
    LCD_WriteString(buffer);
    LCD_WriteData('.');

    buffer[0] = 0;
    utoa(buffer,MINOR_REV,10);
    LCD_WriteString(buffer);
    LCD_WriteData('.');

    buffer[0] = 0;
    utoa(buffer,LCD_GetBusyBitMask(),10);
    LCD_WriteString(buffer);
}
/*
 * Display application name and version
 */
void ShowLCDSymbols(unsigned char Symbol)
{
    unsigned char buffer[17];
    unsigned char count;
    
    LCD_SetDDRamAddr(LINE_ONE);
    LCD_WriteConstString("Symbols:        ");
    LCD_SetDDRamAddr(LINE_ONE+9);
    buffer[0] = 0;
    utoa(buffer,Symbol,10);
    LCD_WriteString(buffer);
    LCD_WriteData('-');

    buffer[0] = 0;
    utoa(buffer,Symbol+15U,10);
    LCD_WriteString(buffer);

    LCD_SetDDRamAddr(LINE_TWO);
    for(count = 0; count < 16; count++)
    {
        LCD_WriteData(Symbol++);
    }
}
/*
 * 
 */
void ShowLCDHexByte(unsigned char HexByte)
{
    unsigned char buffer[17];
    unsigned char index;

    buffer[0] = 0;
    utoa(buffer,HexByte,16);
    LCD_WriteString(buffer);
}
/*
 * 
 */
void ShowLCDDecByte(unsigned char DecByte)
{
    unsigned char buffer[17];
    unsigned char index;

    buffer[0] = 0;
    utoa(buffer,DecByte,10);
    LCD_WriteString(buffer);
}
/*
 * Main program
 */
#define I2C_TC74   (0x9A)
#define I2C_EEPROM (0xA0)
#define I2C_BRG    ((FSYS/(400000ul*4))-1)
#define EEPROM_ADDRESS (0x03)

void main(void) {
    
    unsigned char ButtonState;
    unsigned char LCD_symbols;
    unsigned char I2C_data[4];
    I2C_Result_t status;
    unsigned char I2C_ProbeAddress;
    
    PIC_Init();
    LCD_Init();
    SSP1ADD = I2C_BRG;
    I2C1_Init(MASTER,SLEW_ON);
    TIMER0_Init();
    Buttons_Init();
    gButtonEvent = 0;
    INTCONbits.GIE = 1;
    LCD_symbols = 0;

    /* Display the application name and version information */
    ShowVersion();
    /* Show what is in the character generator RAM */
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteConstString("\010\011\012\013\014\015\016\017"); /* octal byte constants in a string */
    LCD_WriteConstString(" 17JUN11");

    TRISB &= 0xF0;      /* make PORTB bits 0-3 outputs */
    LATB  &= 0xF0;      /* turn off LEDs on PORTB bits 0-3 */
#if 0
    /*
     * Enumerate the I2C address space
     */
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteConstString("                ");
    LCD_SetDDRamAddr(LINE_TWO);
    I2C_ProbeAddress = 0;
    for(I2C_ProbeAddress = 0; I2C_ProbeAddress < 128u; I2C_ProbeAddress++)
    {
        if(I2C1_AckProbe((unsigned char)(I2C_ProbeAddress << 1)) == S_OK)
        {
            ShowLCDHexByte((unsigned char)(I2C_ProbeAddress << 1));
            LCD_WriteData(' ');
        }
    };
    /*
     * Test EEPROM
     */
    status = I2C1_SequentialRead(I2C_EEPROM, EEPROM_ADDRESS, I2C_data, 1);
    I2C_data[0]++;
    status = I2C1_SequentialWrite(I2C_EEPROM, EEPROM_ADDRESS, I2C_data, 1);
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteConstString("R        W      ");
    LCD_SetDDRamAddr(LINE_TWO+10);
    ShowLCDHexByte(status);
    LCD_SetDDRamAddr(LINE_TWO+1);
    I2C1_AckPolling(I2C_EEPROM);
    I2C_data[0] = 0;
    status = I2C1_SequentialRead(I2C_EEPROM, EEPROM_ADDRESS, I2C_data, 1);
    ShowLCDHexByte(status);
    LCD_WriteData('@');
    ShowLCDHexByte(EEPROM_ADDRESS);
    LCD_WriteData('=');
    ShowLCDHexByte(I2C_data[0]);
#endif
    /*
     * Initialize TC75
     */
    I2C_data[1] = 0x01; /* TC75, RWCR register */
    I2C_data[0] = 0x00; /* TC75, assert normal mode */
    I2C1_SequentialWrite(I2C_EEPROM, 0x0100, I2C_data, 1);
    //I2C1_Transaction(I2C_TC74, I2C_data, 2, 0, 0);
    LCD_SetDDRamAddr(LINE_TWO);
    LCD_WriteConstString("                ");
    NOP();
    NOP();
    NOP();
    
    /*
     * Application loop
     */
    for(;;)
    {
        if (gTick)
        {
            I2C_data[1] = 0x00; /* TC75, assert normal mode */
            I2C_data[0] = 0x00; /* TC75, assert normal mode */
//            I2C1_Transaction(I2C_TC74, I2C_data, 2, 0, 0);
            I2C1_SequentialRead(I2C_EEPROM, 0x0000, I2C_data, 1);
            LCD_SetDDRamAddr(LINE_TWO);
            if(I2C_data[0] & 0x80u)
            {
                LCD_WriteData('-');
                I2C_data[0] ^= 0xFF;
                I2C_data[0]++;
            }
            ShowLCDDecByte(I2C_data[0]);
            LCD_WriteConstString("\337C");
        }
        
        if (gButtonEvent)
        {
            gButtonEvent = 0;
            
            ButtonState = Buttons_GetStatus();
            if( ButtonState & BUTTON_S2_CHANGE_MASK)
            { /* if S2 changed */
                if ( ButtonState & BUTTON_S2_STATE_MASK )
                { /* is S2 changed to pressed */
                    ShowLCDSymbols(LCD_symbols);
                    LCD_symbols += 16;
                }
            }
            if( ButtonState & BUTTON_S3_CHANGE_MASK)
            { /* if S3 changed */
                if ( ButtonState & BUTTON_S3_STATE_MASK )
                { /* is S3 changed to pressed */
                    LATB = (LATB & 0xF0U) | ((LATB + 1U) & 0x0FU);
                }
            }
        }
    }
}
/*
 * Interrupt handlers
 */
void interrupt ISR_Handler(void)
{
    /* Handle system tick */
    if (PIE0bits.TMR0IE)
    {
        if(PIR0bits.TMR0IF)
        {
            PIR0bits.TMR0IF = 0;
            gTick++;
            
            if (Buttons_Poll() & (BUTTON_S2_CHANGE_MASK | BUTTON_S3_CHANGE_MASK))
            {
                if(!gButtonEvent)
                {
                    gButtonEvent = 1;
                }
            }
        }
    }
}
