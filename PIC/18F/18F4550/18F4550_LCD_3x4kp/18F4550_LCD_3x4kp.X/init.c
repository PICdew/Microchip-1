/*
 * File:   init.c
 * Author:
 *
 * Target: PIC18F4550
 *
 *
 *
 *                               PIC18F4550
 *                       +----------:_:----------+
 *             VPP ->  1 : MCLR/VPP      PGD/RB7 : 40 <> PGD
 *          VOLT_1 ->  2 : RA0/AN0       PGC/RB6 : 39 <> PGC
 *          VOLT_2 ->  3 : RA1/AN1       PGM/RB5 : 38 -> KP_COL3_OUT
 *          VOLT_3 ->  4 : RA2/AN2      AN11/RB4 : 37 -> KP_COL2_OUT
 *       CURRENT_1 ->  5 : RA3/AN3       AN9/RB3 : 36 <- KP_ROW4_IN
 *                 <>  6 : RA4           AN8/RB2 : 35 <- KP_ROW3_IN
 *       CURRENT_2 ->  7 : RA5/AN4       SCL/RB1 : 34 <- KP_ROW2_IN
 *       CURRENT_3 ->  8 : RE0/AN5       SDA/RB0 : 33 <- KP_ROW1_IN
 *   TEMPERATURE_1 ->  9 : RE1/AN6           VDD : 32 <- PWR
 *   TEMPERATURE_2 -> 10 : RE2/AN7           VSS : 31 <- GND
 *             PWR -> 11 : VDD               RD7 : 30 -> LCD_ON
 *             GND -> 12 : VSS               RD6 : 29 -> LCD_E
 *           20MHZ -> 13 : OSC1              RD5 : 28 -> LCD_RW
 *           20MHZ <- 14 : OSC2              RD4 : 27 -> LCD_RS
 *     KP_COL1_OUT <- 15 : RC0         RX/DT/RC7 : 26 <- RXD
 *            PWM2 <- 16 : RC1/CCP2    TX/CK/RC6 : 25 -> TXD
 *            PWM1 <- 17 : RC2/CCP1       D+/RC5 : 24 <-
 *                 <> 18 : VUSB           D-/RC4 : 23 <-
 *          LCD_D4 <> 19 : RD0               RD3 : 22 <> LCD_D7
 *          LCD_D5 <> 20 : RD1               RD2 : 21 <> LCD_D6
 *                       +-----------------------:
 *                                DIP-40
 *
 *   LCD Module        PIC        Keypad 3x4        PIC
 *   MC21605C6W-SPR  PIN GPIO     MCAK304NBWB     PIN GPIO   Key Caps
 *   [ 1]GND         [12]GND      [1]KP_COL2_OUT  [37]RB4    [1][2][3] R1
 *   [ 2]PWR         [11]PWR      [2]KP_ROW1_IN   [33]RB0    [4][5][6] R2
 *   [ 3]CONTRAST    [12]GND      [3]KP_COL1_OUT  [15]RC0    [7][8][9] R3
 *   [ 4]LCD_RS      [27]RD4      [4]KP_ROW4_IN   [36]RB3    [*][0][#] R4
 *   [ 5]LCD_RW      [28]RD5      [5]KP_COL3_OUT  [38]RB5     C  C  C
 *   [ 6]LCD_E       [29]RD6      [6]KP_ROW3_IN   [35]RB2     1  2  3
 *   [11]LCD_D4      [19]RD0      [7]KP_ROW2_IN   [34]RB1
 *   [12]LCD_D5      [20]RD1
 *   [13]LCD_D6      [21]RD2
 *   [14]LCD_D7      [22]RD3
 *
 */
#pragma config PLLDIV = 5           /* PLL Prescaler Selection bits (Divide by 5 (20 MHz oscillator input)) */
#pragma config CPUDIV = OSC1_PLL2   /* System Clock Postscaler Selection bits ([Primary Oscillator Src: /1][96 MHz PLL Src: /2]) */
#pragma config USBDIV = 2           /* USB Clock Selection bit (used in Full-Speed USB mode only; UCFG:FSEN = 1) (USB clock source comes from the 96 MHz PLL divided by 2) */
#pragma config FOSC = HSPLL_HS      /* Oscillator Selection bits (HS oscillator, PLL enabled (HSPLL)) */
#pragma config FCMEN = OFF          /* Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled) */
#pragma config IESO = OFF           /* Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled) */
#pragma config PWRT = OFF           /* Power-up Timer Enable bit (PWRT disabled) */
#pragma config BOR = OFF            /* Brown-out Reset Enable bits (Brown-out Reset disabled in hardware and software) */
#pragma config BORV = 3             /* Brown-out Reset Voltage bits (Minimum setting 2.05V) */
#pragma config VREGEN = ON          /* USB Voltage Regulator Enable bit (USB voltage regulator enabled) */
#pragma config WDT = OFF            /* Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit)) */
#pragma config WDTPS = 32768        /* Watchdog Timer Postscale Select bits (1:32768) */
#pragma config CCP2MX = ON          /* CCP2 MUX bit (CCP2 input/output is multiplexed with RC1) */
#pragma config PBADEN = OFF         /* PORTB A/D Enable bit (PORTB<4:0> pins are configured as digital I/O on Reset) */
#pragma config LPT1OSC = OFF        /* Low-Power Timer 1 Oscillator Enable bit (Timer1 configured for higher power operation) */
#pragma config MCLRE = ON           /* MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled) */
#pragma config STVREN = ON          /* Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset) */
#pragma config LVP = OFF            /* Single-Supply ICSP Enable bit (Single-Supply ICSP disabled) */
#pragma config ICPRT = OFF          /* Dedicated In-Circuit Debug/Programming Port (ICPORT) Enable bit (ICPORT disabled) */
#pragma config XINST = OFF          /* Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode)) */
#pragma config CP0 = OFF            /* Code Protection bit (Block 0 (000800-001FFFh) is not code-protected) */
#pragma config CP1 = OFF            /* Code Protection bit (Block 1 (002000-003FFFh) is not code-protected) */
#pragma config CP2 = OFF            /* Code Protection bit (Block 2 (004000-005FFFh) is not code-protected) */
#pragma config CPB = OFF            /* Boot Block Code Protection bit (Boot block (000000-0007FFh) is not code-protected) */
#pragma config CPD = OFF            /* Data EEPROM Code Protection bit (Data EEPROM is not code-protected) */
#pragma config WRT0 = OFF           /* Write Protection bit (Block 0 (000800-001FFFh) is not write-protected) */
#pragma config WRT1 = OFF           /* Write Protection bit (Block 1 (002000-003FFFh) is not write-protected) */
#pragma config WRT2 = OFF           /* Write Protection bit (Block 2 (004000-005FFFh) is not write-protected) */
#pragma config WRTC = OFF           /* Configuration Register Write Protection bit (Configuration registers (300000-3000FFh) are not write-protected) */
#pragma config WRTB = OFF           /* Boot Block Write Protection bit (Boot block (000000-0007FFh) is not write-protected) */
#pragma config WRTD = OFF           /* Data EEPROM Write Protection bit (Data EEPROM is not write-protected) */
#pragma config EBTR0 = OFF          /* Table Read Protection bit (Block 0 (000800-001FFFh) is not protected from table reads executed in other blocks) */
#pragma config EBTR1 = OFF          /* Table Read Protection bit (Block 1 (002000-003FFFh) is not protected from table reads executed in other blocks) */
#pragma config EBTR2 = OFF          /* Table Read Protection bit (Block 2 (004000-005FFFh) is not protected from table reads executed in other blocks) */
#pragma config EBTRB = OFF          /* Boot Block Table Read Protection bit (Boot block (000000-0007FFh) is not protected from table reads executed in other blocks) */


#include <xc.h>
#include "init.h"

void PIC_Init(void) {
    INTCON = 0;     /* disable interrupts */
    INTCON2 = 0xF5;
    INTCON3 = 0xC0;
    PIE1 = 0;
    PIE2 = 0;

    OSCCON = 0x70;      /* set internal oscillator to 8 MHz */

    RCONbits.IPEN = 0;  /* use legacy interrupt model */

    ADCON1 = 0x07;      /* Enable ADC inputs AN0 to AN7 */

    CMCON  = 0x07;      /* disable Comparators */

    LATA   = 0x00;
    TRISA  = 0xEF;      /* Analog inputs for AN0,AN1,AN2,AN3,AN4, RA4 is a digital output, RA6,RA7 used for the 20MHz crystal oscillator */
    LATB   = 0x30;
    TRISB  = 0x0F;      /* RB0-3 are keypad row inputs, RB4,RB5 are keypad COL2,COL3 drivers, RB6,RB7 are used for In-Circuit-Debug */
    INTCON2bits.nRBPU = 0; /* enable PORTB pull-ups for inputs */
    LATC   = 0x00;
    TRISC  = 0x31;      /* RC0 is keypad COL1 driver, RC4 & RC5 are input only pins when not using the USB */
    LATD   = 0x00;
    TRISD  = 0x00;
    LATE   = 0x00;
    TRISE |= 0x07;     /* Analog inputs AN5,AN6,AN7 */
    return;
}
