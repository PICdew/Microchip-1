/* 
 * File:     init.c
 * Target:   PIC16F18877
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.61
 *
 */
#include <stdbool.h>
#include "init.h"

#pragma config FEXTOSC = OFF    // External Oscillator mode selection bits (Oscillator not enabled)
#pragma config RSTOSC = HFINT32 // Power-up default value for COSC bits (HFINTOSC with OSCFRQ= 32 MHz and CDIV = 1:1)
#pragma config CLKOUTEN = OFF   // Clock Out Enable bit (CLKOUT function is disabled; i/o or oscillator function on OSC2)
#pragma config CSWEN = ON       // Clock Switch Enable bit (Writing to NOSC and NDIV is allowed)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enable bit (FSCM timer disabled)
#pragma config MCLRE = ON       // Master Clear Enable bit (MCLR pin is Master Clear function)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config LPBOREN = OFF    // Low-Power BOR enable bit (ULPBOR disabled)
#pragma config BOREN = OFF      // Brown-out reset enable bits (Brown-out reset disabled)
#pragma config BORV = LO        // Brown-out Reset Voltage Selection (Brown-out Reset Voltage (VBOR) set to 1.9V on LF, and 2.45V on F Devices)
#pragma config ZCD = OFF        // Zero-cross detect disable (Zero-cross detect circuit is disabled at POR.)
#pragma config PPS1WAY = OFF    // Peripheral Pin Select one-way control (The PPSLOCK bit can be set and cleared repeatedly by software)
#pragma config STVREN = ON      // Stack Overflow/Underflow Reset Enable bit (Stack Overflow or Underflow will cause a reset)
#pragma config WDTCPS = WDTCPS_31// WDT Period Select bits (Divider ratio 1:65536; software control of WDTPS)
#pragma config WDTE = SWDTEN    // WDT operating mode (WDT enabled/disabled by SWDTEN bit in WDTCON0)
#pragma config WDTCWS = WDTCWS_7// WDT Window Select bits (window always open (100%); software control; keyed access not required)
#pragma config WDTCCS = SC      // WDT input clock selector (Software Control)
#pragma config WRT = OFF        // UserNVM self-write protection bits (Write protection off)
#pragma config SCANE = available// Scanner Enable bit (Scanner module is available for use)
#pragma config LVP = ON         // Low Voltage Programming Enable bit (Low Voltage programming enabled. MCLR/Vpp pin function is MCLR.)
#pragma config CP = OFF         // UserNVM Program memory code protection bit (Program Memory code protection disabled)
#pragma config CPD = OFF        // DataNVM code protection bit (Data EEPROM code protection disabled)

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
    RPI_RD0 = 0x18,
    RPI_RD1 = 0x19,
    RPI_RD2 = 0x1A,
    RPI_RD3 = 0x1B,
    RPI_RD4 = 0x1C,
    RPI_RD5 = 0x1D,
    RPI_RD6 = 0x1E,
    RPI_RD7 = 0x1F,
    RPI_RE0 = 0x20,
    RPI_RE1 = 0x21,
    RPI_RE2 = 0x22,
    RPI_RE3 = 0x23,
    RPI_NONE = 0xFF
};

enum
{
    RPOac_ADGRDG  = 0x25,
    RPOac_ADGRDA  = 0x24,
    RPOad_CWG3D   = 0x23,
    RPOad_CWG3C   = 0x22,
    RPOae_CWG3B   = 0x21,
    RPObc_CWG3A   = 0x20,
    RPObd_CWG2D   = 0x1F,
    RPObd_CWG2C   = 0x1E,
    RPObd_CWG2B   = 0x1D,
    RPObc_CWG2A   = 0x1C,
    RPOad_DSM     = 0x1B,
    RPObc_CLKR    = 0x1A,
    RPOad_NCO     = 0x19,
    RPObc_TMR0    = 0x18,
    RPObd_SDA2    = 0x17,
    RPObd_SCL2    = 0x16,
    RPObc_SDA1    = 0x15,
    RPObc_SCL1    = 0x14,
    RPOae_C2OUT   = 0x13,
    RPOad_C1OUT   = 0x12,
    RPObc_DT      = 0x11,
    RPObc_TX      = 0x10,
    RPOac_PWM7OUT = 0x0F,
    RPOad_PWM6OUT = 0x0E,
    RPOae_CCP5    = 0x0D,
    RPObd_CCP4    = 0x0C,
    RPObd_CCP3    = 0x0B,
    RPObc_CCP2    = 0x0A,
    RPObc_CCP1    = 0x09,
    RPObd_CWG1D   = 0x08,
    RPObd_CWG1C   = 0x07,
    RPObd_CWG1B   = 0x06,
    RPObc_CWG1A   = 0x05,
    RPObd_CLC4OUT = 0x04,
    RPObd_CLC3OUT = 0x03,
    RPOac_CLC2OUT = 0x02,
    RPOac_CLC1OUT = 0x01,
    RPO_NONE      = 0x00
};

void Init_PIC( void )
{
    /* Disable all interrupt sources */
    INTCON = 0;
    PIE0   = 0;
    PIE1   = 0;
    PIE2   = 0;
    PIE3   = 0;
    PIE4   = 0;
    PIE5   = 0;
    PIE6   = 0;
    PIE7   = 0;

    /* Do system clock setup */
    OSCFRQ  = 0;            /* Set internal HFRC to 32MHz */
    OSCTUNE = 0;            /* Set oscillator tuning to factory default */
    
    /* Make all GPIO pins digital */
    ANSELA = 0;
    ANSELB = 0;
    ANSELC = 0;
    ANSELD = 0;
    ANSELE = 0;

    /* map all PPS to defaults */
    PPSLOCK = 0x55;
    PPSLOCK = 0xAA;
    PPSLOCKbits.PPSLOCKED = 0x00; // unlock PPS
    
    INTPPS     = RPI_RB0;      /* RA | RB */
    T0CKIPPS   = RPI_RA4;      /* RA | RB */
    T1CKIPPS   = RPI_RC0;      /* RA | RC */
    T1GPPS     = RPI_RB5;      /* RB | RC */
    T3CKIPPS   = RPI_RC0;      /* RB | RC */
    T3GPPS     = RPI_RC0;      /* RA | RC */
    T5CKIPPS   = RPI_RC2;      /* RA | RC */
    T5GPPS     = RPI_RB4;      /* RB | RD */
    T2AINPPS   = RPI_RC3;      /* RB | RD */
    T4AINPPS   = RPI_RC5;      /* RB | RC */
    T6AINPPS   = RPI_RB7;      /* RB | RD */
    CCP1PPS    = RPI_RC2;      /* RB | RC */
    CCP2PPS    = RPI_RC1;      /* RB | RC */
    CCP3PPS    = RPI_RB5;      /* RB | RD */
    CCP4PPS    = RPI_RB0;      /* RB | RD */
    CCP5PPS    = RPI_RA4;      /* RA | RE */
    SMT1WINPPS = RPI_RC0;      /* RB | RC */
    SMT1SIGPPS = RPI_RC1;      /* RB | RC */
    SMT2WINPPS = RPI_RB4;      /* RB | RD */
    SMT2SIGPPS = RPI_RB5;      /* RB | RD */
    CWG1PPS    = RPI_RB0;      /* RB | RD */
    CWG2PPS    = RPI_RB1;      /* RB | RD */
    CWG3PPS    = RPI_RB2;      /* RB | RD */
    MDCARLPPS  = RPI_RA3;      /* RA | RD */
    MDCARHPPS  = RPI_RA4;      /* RA | RD */
    MDSRCPPS   = RPI_RA5;      /* RA | RD */
    CLCIN0PPS  = RPI_RA0;      /* RA | RC */
    CLCIN1PPS  = RPI_RA1;      /* RA | RC */
    CLCIN2PPS  = RPI_RB6;      /* RB | RD */
    CLCIN3PPS  = RPI_RB7;      /* RB | RD */
    ADCACTPPS  = RPI_RB4;      /* RB | RD */
    SSP1CLKPPS = RPI_RC3;      /* RB | RC */
    SSP1DATPPS = RPI_RC4;      /* RB | RC */
    SSP1SSPPS  = RPI_RA5;      /* RA | RD */
    SSP2CLKPPS = RPI_RB1;      /* RB | RD */
    SSP2DATPPS = RPI_RB2;      /* RB | RD */
    SSP2SSPPS  = RPI_RB0;      /* RB | RD */
    RXPPS      = RPI_RC7;      /* RB | RC */
    TXPPS      = RPI_RC6;      /* RB | RC */
    

    RA0PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3D,CWG3C,CWG3B,DSM,NCO,COUT2,COUT1PWM7OUT,PWM6OUT,CCP5,CLC2OUT,CLC1OUT */
    RA1PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3D,CWG3C,CWG3B,DSM,NCO,COUT2,COUT1PWM7OUT,PWM6OUT,CCP5,CLC2OUT,CLC1OUT */
    RA2PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3D,CWG3C,CWG3B,DSM,NCO,COUT2,COUT1PWM7OUT,PWM6OUT,CCP5,CLC2OUT,CLC1OUT */
    RA3PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3D,CWG3C,CWG3B,DSM,NCO,COUT2,COUT1PWM7OUT,PWM6OUT,CCP5,CLC2OUT,CLC1OUT */
    RA4PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3D,CWG3C,CWG3B,DSM,NCO,COUT2,COUT1PWM7OUT,PWM6OUT,CCP5,CLC2OUT,CLC1OUT */
    RA5PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3D,CWG3C,CWG3B,DSM,NCO,COUT2,COUT1PWM7OUT,PWM6OUT,CCP5,CLC2OUT,CLC1OUT */
    RA6PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3D,CWG3C,CWG3B,DSM,NCO,COUT2,COUT1PWM7OUT,PWM6OUT,CCP5,CLC2OUT,CLC1OUT */
    RA7PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3D,CWG3C,CWG3B,DSM,NCO,COUT2,COUT1PWM7OUT,PWM6OUT,CCP5,CLC2OUT,CLC1OUT */
    RB0PPS = RPO_NONE;  /* CEG3A,CWG2D,CWG2C,CWG2B,CWG2A,DSM,CLKR,TRM0,SDO2/SDA2,SCK2/SCL2,SDO1/SDA1,SCK1/SCL1,DT,TX/CK,CCP4,CCP3,CCP2,CCP1,CWG1D,CWG1C,CWG1B,CWG1A,CLC4OUT,CLC3OUT */
    RB1PPS = RPO_NONE;  /* CEG3A,CWG2D,CWG2C,CWG2B,CWG2A,DSM,CLKR,TRM0,SDO2/SDA2,SCK2/SCL2,SDO1/SDA1,SCK1/SCL1,DT,TX/CK,CCP4,CCP3,CCP2,CCP1,CWG1D,CWG1C,CWG1B,CWG1A,CLC4OUT,CLC3OUT */
    RB2PPS = RPO_NONE;  /* CEG3A,CWG2D,CWG2C,CWG2B,CWG2A,DSM,CLKR,TRM0,SDO2/SDA2,SCK2/SCL2,SDO1/SDA1,SCK1/SCL1,DT,TX/CK,CCP4,CCP3,CCP2,CCP1,CWG1D,CWG1C,CWG1B,CWG1A,CLC4OUT,CLC3OUT */
    RB3PPS = RPO_NONE;  /* CEG3A,CWG2D,CWG2C,CWG2B,CWG2A,DSM,CLKR,TRM0,SDO2/SDA2,SCK2/SCL2,SDO1/SDA1,SCK1/SCL1,DT,TX/CK,CCP4,CCP3,CCP2,CCP1,CWG1D,CWG1C,CWG1B,CWG1A,CLC4OUT,CLC3OUT */
    RB4PPS = RPO_NONE;  /* CEG3A,CWG2D,CWG2C,CWG2B,CWG2A,DSM,CLKR,TRM0,SDO2/SDA2,SCK2/SCL2,SDO1/SDA1,SCK1/SCL1,DT,TX/CK,CCP4,CCP3,CCP2,CCP1,CWG1D,CWG1C,CWG1B,CWG1A,CLC4OUT,CLC3OUT */
    RB5PPS = RPO_NONE;  /* CEG3A,CWG2D,CWG2C,CWG2B,CWG2A,DSM,CLKR,TRM0,SDO2/SDA2,SCK2/SCL2,SDO1/SDA1,SCK1/SCL1,DT,TX/CK,CCP4,CCP3,CCP2,CCP1,CWG1D,CWG1C,CWG1B,CWG1A,CLC4OUT,CLC3OUT */
    RB6PPS = RPO_NONE;  /* CEG3A,CWG2D,CWG2C,CWG2B,CWG2A,DSM,CLKR,TRM0,SDO2/SDA2,SCK2/SCL2,SDO1/SDA1,SCK1/SCL1,DT,TX/CK,CCP4,CCP3,CCP2,CCP1,CWG1D,CWG1C,CWG1B,CWG1A,CLC4OUT,CLC3OUT */
    RB7PPS = RPO_NONE;  /* CEG3A,CWG2D,CWG2C,CWG2B,CWG2A,DSM,CLKR,TRM0,SDO2/SDA2,SCK2/SCL2,SDO1/SDA1,SCK1/SCL1,DT,TX/CK,CCP4,CCP3,CCP2,CCP1,CWG1D,CWG1C,CWG1B,CWG1A,CLC4OUT,CLC3OUT */
    RC0PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3A,CWG2A,CLKR,TMR0,SD01/SDA1,SCK1/SCL1,DT,TX/CK,PWM7OUT,CCP2,CCP1,CWG1A,CLC2OUT,CLC1OUT */
    RC1PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3A,CWG2A,CLKR,TMR0,SD01/SDA1,SCK1/SCL1,DT,TX/CK,PWM7OUT,CCP2,CCP1,CWG1A,CLC2OUT,CLC1OUT */
    RC2PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3A,CWG2A,CLKR,TMR0,SD01/SDA1,SCK1/SCL1,DT,TX/CK,PWM7OUT,CCP2,CCP1,CWG1A,CLC2OUT,CLC1OUT */
    RC3PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3A,CWG2A,CLKR,TMR0,SD01/SDA1,SCK1/SCL1,DT,TX/CK,PWM7OUT,CCP2,CCP1,CWG1A,CLC2OUT,CLC1OUT */
    RC4PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3A,CWG2A,CLKR,TMR0,SD01/SDA1,SCK1/SCL1,DT,TX/CK,PWM7OUT,CCP2,CCP1,CWG1A,CLC2OUT,CLC1OUT */
    RC5PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3A,CWG2A,CLKR,TMR0,SD01/SDA1,SCK1/SCL1,DT,TX/CK,PWM7OUT,CCP2,CCP1,CWG1A,CLC2OUT,CLC1OUT */
    RC6PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3A,CWG2A,CLKR,TMR0,SD01/SDA1,SCK1/SCL1,DT,TX/CK,PWM7OUT,CCP2,CCP1,CWG1A,CLC2OUT,CLC1OUT */
    RC7PPS = RPO_NONE;  /* ADGRDG,ADGRDA,CWG3A,CWG2A,CLKR,TMR0,SD01/SDA1,SCK1/SCL1,DT,TX/CK,PWM7OUT,CCP2,CCP1,CWG1A,CLC2OUT,CLC1OUT */
    RD0PPS = RPO_NONE;  /* CWG3D,CWG3C,CWG2D,CWG2C,CWG2B,DSM,NCO,SDO2/SDA2,SCK2/SCL2,C1OUT,PWM6OUT,CCP4,CCP3,CWG1D,CWG1C,CWG1B,CLC4OUT,CLC3OUT */
    RD1PPS = RPO_NONE;  /* CWG3D,CWG3C,CWG2D,CWG2C,CWG2B,DSM,NCO,SDO2/SDA2,SCK2/SCL2,C1OUT,PWM6OUT,CCP4,CCP3,CWG1D,CWG1C,CWG1B,CLC4OUT,CLC3OUT */
    RD2PPS = RPO_NONE;  /* CWG3D,CWG3C,CWG2D,CWG2C,CWG2B,DSM,NCO,SDO2/SDA2,SCK2/SCL2,C1OUT,PWM6OUT,CCP4,CCP3,CWG1D,CWG1C,CWG1B,CLC4OUT,CLC3OUT */
    RD3PPS = RPO_NONE;  /* CWG3D,CWG3C,CWG2D,CWG2C,CWG2B,DSM,NCO,SDO2/SDA2,SCK2/SCL2,C1OUT,PWM6OUT,CCP4,CCP3,CWG1D,CWG1C,CWG1B,CLC4OUT,CLC3OUT */
    RD4PPS = RPO_NONE;  /* CWG3D,CWG3C,CWG2D,CWG2C,CWG2B,DSM,NCO,SDO2/SDA2,SCK2/SCL2,C1OUT,PWM6OUT,CCP4,CCP3,CWG1D,CWG1C,CWG1B,CLC4OUT,CLC3OUT */
    RD5PPS = RPO_NONE;  /* CWG3D,CWG3C,CWG2D,CWG2C,CWG2B,DSM,NCO,SDO2/SDA2,SCK2/SCL2,C1OUT,PWM6OUT,CCP4,CCP3,CWG1D,CWG1C,CWG1B,CLC4OUT,CLC3OUT */
    RD6PPS = RPO_NONE;  /* CWG3D,CWG3C,CWG2D,CWG2C,CWG2B,DSM,NCO,SDO2/SDA2,SCK2/SCL2,C1OUT,PWM6OUT,CCP4,CCP3,CWG1D,CWG1C,CWG1B,CLC4OUT,CLC3OUT */
    RD7PPS = RPO_NONE;  /* CWG3D,CWG3C,CWG2D,CWG2C,CWG2B,DSM,NCO,SDO2/SDA2,SCK2/SCL2,C1OUT,PWM6OUT,CCP4,CCP3,CWG1D,CWG1C,CWG1B,CLC4OUT,CLC3OUT */
    RE0PPS = RPO_NONE;  /* CWG3B,C2OUT,CCP5 */
    RE1PPS = RPO_NONE;  /* CWG3B,C2OUT,CCP5 */
    RE2PPS = RPO_NONE;  /* CWG3B,C2OUT,CCP5 */

    PPSLOCK = 0x55;
    PPSLOCK = 0xAA;
    PPSLOCKbits.PPSLOCKED = 0x01; // lock PPS
}
