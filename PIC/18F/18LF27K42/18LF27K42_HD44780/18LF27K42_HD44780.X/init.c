/* 
 * File:     init.c
 * Author:   dan1138
 * Target:   PIC18F27K42
 * Compiler: XC8 v1.45
 * IDE:      MPLABX v4.05
 *
 */
#include <stdbool.h>
#include "init.h"

#pragma config FEXTOSC = HS, RSTOSC = EXTOSC, CLKOUTEN = OFF, PR1WAY = OFF
#pragma config CSWEN = ON, FCMEN = OFF, MCLRE = EXTMCLR, PWRTS = PWRT_OFF
#pragma config MVECEN = OFF, IVT1WAY = OFF, LPBOREN = OFF, BOREN = OFF
#pragma config BORV = VBOR_245, ZCD = OFF, PPS1WAY = OFF, STVREN = ON
#pragma config DEBUG = OFF, XINST = OFF, WDTCPS = WDTCPS_31, WDTE = OFF
#pragma config WDTCWS = WDTCWS_7, WDTCCS = LFINTOSC, BBSIZE = BBSIZE_512
#pragma config BBEN = OFF, SAFEN = OFF, WRTAPP = OFF, WRTB = OFF, WRTC = OFF
#pragma config WRTD = OFF, WRTSAF = OFF, LVP = ON, CP = OFF

enum
{
    RPI_RA0 = 0x00,
    RPI_RA1 = 0x01,
    RPI_RA2 = 0x02,
    RPI_RA3 = 0x03,
    RPI_RA4 = 0x04,
    RPI_RA5 = 0x05,
    RPI_RA6 = 0x06,
    RPI_RA7 = 0x07,
    RPI_RB0 = 0x08,
    RPI_RB1 = 0x09,
    RPI_RB2 = 0x0A,
    RPI_RB3 = 0x0B,
    RPI_RB4 = 0x0C,
    RPI_RB5 = 0x0D,
    RPI_RB6 = 0x0E,
    RPI_RB7 = 0x0F,
    RPI_RC0 = 0x10,
    RPI_RC1 = 0x11,
    RPI_RC2 = 0x12,
    RPI_RC3 = 0x13,
    RPI_RC4 = 0x14,
    RPI_RC5 = 0x15,
    RPI_RC6 = 0x16,
    RPI_RC7 = 0x17,
    RPI_NONE = 0xFF
};

enum
{
    RPOac_ADGRDB    = 0b110010,
    RPOac_ADGRDA    = 0b110001,
    RPOac_CWG3D     = 0b110000,
    RPOac_CWG3C     = 0b101111,
    RPOac_CWG3B     = 0b101110,
    RPObc_CWG3A     = 0b101101,
    RPObc_CWG2D     = 0b101100,
    RPObc_CWG2C     = 0b101011,
    RPObc_CWG2B     = 0b101010,
    RPObc_CWG2A     = 0b101001,
    RPOac_DSM1      = 0b101000,
    RPObc_CLKR      = 0b100111,
    RPOac_NCO1      = 0b100110,
    RPObc_TMR0      = 0b100101,
    RPObc_I2C2_SDA  = 0b100100,
    RPObc_I2C2_SCL  = 0b100011,
    RPObc_I2C1_SDA  = 0b100010,
    RPObc_I2C1_SCL  = 0b100001,
    RPOac_SPI1_SS   = 0b100000,
    RPObc_SPI1_SDO  = 0b011111,
    RPObc_SPI1_SCK  = 0b011110,
    RPOac_C2OUT     = 0b011101,
    RPOac_C1OUT     = 0b011100,
    RPObc_UART2_RTS = 0b011000,
    RPObc_UART2_TXDE= 0b010111,
    RPObc_UART2_TX  = 0b010110,
    RPObc_UART1_RTS = 0b010101,
    RPObc_UART1_TXDE= 0b010100,
    RPObc_UART1_TX  = 0b010011,
    RPOac_PWM8      = 0b010000,
    RPOac_PWM7      = 0b001111,
    RPOac_PWM6      = 0b001110,
    RPOac_PWM5      = 0b001101,
    RPObc_CCP4      = 0b001100,
    RPObc_CCP3      = 0b001011,
    RPObc_CCP2      = 0b001010,
    RPObc_CCP1      = 0b001001,
    RPObc_CWG1D     = 0b001000,
    RPObc_CWG1C     = 0b000111,
    RPObc_CWG1B     = 0b000110,
    RPObc_CWG1A     = 0b000101,
    RPObc_CLC4OUT   = 0b000100,
    RPObc_CLC3OUT   = 0b000011,
    RPOac_CLC2OUT   = 0b000010,
    RPOac_CLC1OUT   = 0b000001,
    RPO_NONE        = 0x00
};

void PIC_Init( void )
{
    /* Disable all interrupt sources */
    INTCON0 = 0;
    PIE0    = 0;
    PIE1    = 0;
    PIE2    = 0;
    PIE3    = 0;
    PIE4    = 0;
    PIE5    = 0;
    PIE6    = 0;
    PIE7    = 0;
    PIE8    = 0;
    PIE9    = 0;
    PIE10   = 0;

    /* Do system clock setup */
    OSCCON1 = 0b01100000;   /* Switch to internal HFINTOSC at 32MHz no divisor */
    OSCFRQ  = 0b110;        /* Set internal HFINTOSC divisor for 32MHz */
    OSCTUNE = 0;            /* Set oscillator tuning to factory default */
    
    /* Make all GPIO pins digital */
    ANSELA = 0;
    ANSELB = 0;
    ANSELC = 0;

    /* map all PPS to defaults */
    PPSLOCK = 0x55;
    PPSLOCK = 0xAA;
    PPSLOCKbits.PPSLOCKED = 0x00; // unlock PPS
    
    INT0PPS     = RPI_RB0;      /* RA | RB */
    INT1PPS     = RPI_RB1;      /* RA | RB */
    INT2PPS     = RPI_RB2;      /* RA | RB */
    T0CKIPPS    = RPI_RA4;      /* RA | RB */
    T1CKIPPS    = RPI_RC0;      /* RA | RC */
    T1GPPS      = RPI_RB5;      /* RB | RC */
    T3CKIPPS    = RPI_RC0;      /* RB | RC */
    T3GPPS      = RPI_RC0;      /* RA | RC */
    T5CKIPPS    = RPI_RC2;      /* RA | RC */
    T5GPPS      = RPI_RB4;      /* RB | RC */
    T2INPPS     = RPI_RC3;      /* RA | RC */
    T4INPPS     = RPI_RC5;      /* RB | RC */
    T6INPPS     = RPI_RB7;      /* RB | RC */
    CCP1PPS     = RPI_RC2;      /* RB | RC */
    CCP2PPS     = RPI_RC1;      /* RB | RC */
    CCP3PPS     = RPI_RB5;      /* RB | RC */
    CCP4PPS     = RPI_RB0;      /* RB | RC */
    SMT1WINPPS  = RPI_RC0;      /* RB | RC */
    SMT1SIGPPS  = RPI_RC1;      /* RB | RC */
    CWG1INPPS   = RPI_RB0;      /* RB | RC */
    CWG2INPPS   = RPI_RB1;      /* RB | RC */
    CWG3INPPS   = RPI_RB2;      /* RB | RC */
    MD1CARLPPS  = RPI_RA3;      /* RA | RC */
    MD1CARHPPS  = RPI_RA4;      /* RA | RC */
    MD1SRCPPS   = RPI_RA5;      /* RA | RC */
    CLCIN0PPS   = RPI_RA0;      /* RA | RC */
    CLCIN1PPS   = RPI_RA1;      /* RA | RC */
    CLCIN2PPS   = RPI_RB6;      /* RB | RC */
    CLCIN3PPS   = RPI_RB7;      /* RB | RC */
    ADACTPPS    = RPI_RB4;      /* RB | RC */
    SPI1SCKPPS  = RPI_RC3;      /* RB | RC */
    SPI1SDIPPS  = RPI_RC4;      /* RB | RC */
    SPI1SSPPS   = RPI_RA5;      /* RA | RC */
    I2C1SCLPPS  = RPI_RC3;      /* RB | RC */
    I2C1SDAPPS  = RPI_RC4;      /* RB | RC */
    I2C2SCLPPS  = RPI_RB1;      /* RB | RC */
    I2C2SDAPPS  = RPI_RB2;      /* RB | RC */
    U1RXPPS     = RPI_RC7;      /* RB | RC */
    U1CTSPPS    = RPI_RC6;      /* RB | RC */
    U2RXPPS     = RPI_RB7;      /* RB | RC */
    U2CTSPPS    = RPI_RB6;      /* RB | RC */


    RA0PPS = RPO_NONE;
    RA1PPS = RPO_NONE;
    RA2PPS = RPO_NONE;
    RA3PPS = RPO_NONE;
    RA4PPS = RPO_NONE;
    RA5PPS = RPO_NONE;
    RA6PPS = RPO_NONE;
    RA7PPS = RPO_NONE;
    RB0PPS = RPO_NONE;
    RB1PPS = RPO_NONE;
    RB2PPS = RPO_NONE;
    RB3PPS = RPO_NONE;
    RB4PPS = RPO_NONE;
    RB5PPS = RPO_NONE;
    RB6PPS = RPO_NONE;
    RB7PPS = RPO_NONE;
    RC0PPS = RPO_NONE;
    RC1PPS = RPO_NONE;
    RC2PPS = RPO_NONE;
    RC3PPS = RPO_NONE;
    RC4PPS = RPO_NONE;
    RC5PPS = RPO_NONE;
    RC6PPS = RPO_NONE;
    RC7PPS = RPO_NONE;

    PPSLOCK = 0x55;
    PPSLOCK = 0xAA;
    PPSLOCKbits.PPSLOCKED = 0x01; // lock PPS

}
