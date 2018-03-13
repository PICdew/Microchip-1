//
// File:   init.c
// Author:
//
// Target: PIC18F24K20, PIC18F2520
//
//                      PIC18F24K20, PIC18F2520
//                   +------------:_:------------+
//         VPP ->  1 : RE3/MCLR/VPP      PGD/RB7 : 28 <> PGD
//             ->  2 : RA0/AN0           PGC/RB6 : 27 <> PGC
//        LED1 <>  3 : RA1/AN1           PGM/RB5 : 26 <> KP_COL2_OUT
//        LED2 <>  4 : RA2/AN2               RB4 : 25 <> KP_COL1_OUT
//      LCD_RS <>  5 : RA3/AN3               RB3 : 24 <> KP_ROW4_IN
//      LCD_RW <>  6 : RA4/C1OUT             RB2 : 23 <> KP_ROW3_IN
//      LCD_E  <>  7 : RA5/AN4               RB1 : 22 <> KP_ROW2_IN
//         GND <>  8 : VSS                   RB0 : 21 <> KP_ROW1_IN
//       20MHz <>  9 : RA7/OSC1              VDD : 20 <- 5v0
//       20MHz <> 10 : RA6/OSC2              VSS : 19 <- GND
//   32.768KHz <> 11 : RC0/SOSCO       RX/DT/RC7 : 18 <> LCD_D7
//   32.768KHz <> 12 : RC1/SOSCI       TX/CK/RC6 : 17 <> LCD_D6
// KP_COL3_OUT <> 13 : RC2/CCP1     SPI_MOSI/RC5 : 16 <> LCD_D5
// KP_COL4_OUT <> 14 : RC3/SPI_CLK  SPI_MISO/RC4 : 15 <> LCD_D4
//                   +---------------------------:
//                              DIP-28
//
//   LCD Module        PIC        Keypad 4x4        PIC
//   MC21605C6W-SPR  PIN GPIO     7207-1610203    PIN GPIO     Key Caps
//   [ 1]GND         [19]GND      [1]KP_ROW1_IN   [21]RB0    [1][2][3][R] R1
//   [ 2]PWR         [20]PWR      [2]KP_ROW2_IN   [22]RB1    [4][5][6][L] R2
//   [ 3]CONTRAST    [ 8]GND      [3]KP_COL1_OUT  [25]RB4    [7][8][9][U] R3
//   [ 4]LCD_RS      [ 5]RA3      [4]KP_COL2_OUT  [26]RB5    [E][0][.][D] R4
//   [ 5]LCD_RW      [ 6]RA4      [5]KP_COL3_OUT  [13]RC2     C  C  C  C
//   [ 6]LCD_E       [ 7]RA5      [6]KP_COL4_OUT  [14]RC3     1  2  3  4
//   [11]LCD_D4      [15]RC4      [7]KP_ROW4_IN   [23]RB3
//   [12]LCD_D5      [16]RC5      [8]KP_ROW3_IN   [24]RB2
//   [13]LCD_D6      [17]RC6
//   [14]LCD_D7      [18]RC7
//
//
module init

#if (_device = 18F24K20)
config FOSC = INTIO67   // Oscillator Selection bits (Internal oscillator block, port function on RA6 and RA7) 
config FCMEN = OFF      // Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled) 
config IESO = OFF       // Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled) 
config PWRT = OFF       // Power-up Timer Enable bit (PWRT disabled) 
config BOREN = OFF      // Brown-out Reset Enable bits (Brown-out Reset disabled in hardware and software) 
config BORV = 18        // Brown Out Reset Voltage bits (VBOR set to 1.8 V nominal) 
config WDTEN = OFF      // Watchdog Timer Enable bit (WDT is controlled by SWDTEN bit of the WDTCON register) 
config WDTPS = 32768    // Watchdog Timer Postscale Select bits (1:32768) 
config CCP2MX = PORTC   // CCP2 MUX bit (CCP2 input/output is multiplexed with RC1) 
config PBADEN = OFF     // PORTB A/D Enable bit (PORTB<4:0> pins are configured as digital I/O on Reset) 
config LPT1OSC = OFF    // Low-Power Timer1 Oscillator Enable bit (Timer1 configured for higher power operation) 
config HFOFST = ON      // HFINTOSC Fast Start-up (HFINTOSC starts clocking the CPU without waiting for the oscillator to stablize.) 
config MCLRE = ON       // MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled) 
config STVREN = ON      // Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset) 
config LVP = OFF        // Single-Supply ICSP Enable bit (Single-Supply ICSP disabled) 
config XINST = OFF      // Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode)) 
config CP0 = OFF        // Code Protection Block 0 (Block 0 (000800-001FFFh) not code-protected) 
config CP1 = OFF        // Code Protection Block 1 (Block 1 (002000-003FFFh) not code-protected) 
config CPB = OFF        // Boot Block Code Protection bit (Boot block (000000-0007FFh) not code-protected) 
config CPD = OFF        // Data EEPROM Code Protection bit (Data EEPROM not code-protected) 
config WRT0 = OFF       // Write Protection Block 0 (Block 0 (000800-001FFFh) not write-protected) 
config WRT1 = OFF       // Write Protection Block 1 (Block 1 (002000-003FFFh) not write-protected) 
config WRTC = OFF       // Configuration Register Write Protection bit (Configuration registers (300000-3000FFh) not write-protected) 
config WRTB = OFF       // Boot Block Write Protection bit (Boot Block (000000-0007FFh) not write-protected) 
config WRTD = OFF       // Data EEPROM Write Protection bit (Data EEPROM not write-protected) 
config EBTR0 = OFF      // Table Read Protection Block 0 (Block 0 (000800-001FFFh) not protected from table reads executed in other blocks) 
config EBTR1 = OFF      // Table Read Protection Block 1 (Block 1 (002000-003FFFh) not protected from table reads executed in other blocks) 
config EBTRB = OFF      // Boot Block Table Read Protection bit (Boot Block (000000-0007FFh) not protected from table reads executed in other blocks) 
#endif

#if (_device = 18F2520)
config OSC = INTIO67    // Oscillator Selection bits (Internal RC oscillator, port function on RA6 and port function on RA7) 
config FCMEN = OFF      // Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled) 
config IESO = OFF       // Internal/External Switchover bit (Internal/External Switchover mode disabled) 
config PWRT = OFF       // Power-up Timer enable bit (PWRT disabled) 
config BOREN = OFF      // Brown-out Reset enable bit (Brown-out Reset disabled) 
config BORV = 3         // Brown-out Reset Voltage bits (VBOR set to 2.0V) 
config WDT = OFF        // Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit)) 
config WDTPS = 32768    // Watchdog Timer Postscale Select bits (1:32768) 
config CCP2MX = PORTC   // CCP2 MUX bit (CCP2 input/output is multiplexed with RC1) 
config PBADEN = OFF     // PORTB A/D Enable bit (PORTB<4:0> pins are configured as digital I/O on Reset) 
config MCLRE = ON       // MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled) 
config STVREN = ON      // Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset) 
config LVP = OFF        // Single-Supply ICSP Enable bit (Single-Supply ICSP disabled) 
config CP0 = OFF        // Code Protection bit (Block 0 (000200-0007FFh) not code-protected) 
config CP1 = OFF        // Code Protection bit (Block 1 (000800-000FFFh) not code-protected) 
config CPB = OFF        // Boot Block Code Protection bit (Boot block (000000-0001FFh) is not code-protected) 
config CPD = OFF        // Data EEPROM Code Protection bit (Data EEPROM is not code-protected) 
config WRT0 = OFF       // Write Protection bit (Block 0 (000200-0007FFh) not write-protected) 
config WRT1 = OFF       // Write Protection bit (Block 1 (000800-000FFFh) not write-protected) 
config WRTC = OFF       // Configuration Register Write Protection bit (Configuration registers (300000-3000FFh) are not write-protected) 
config WRTB = OFF       // Boot Block Write Protection bit (Boot block (000000-0001FFh) is not write-protected) 
config WRTD = OFF       // Data EEPROM Write Protection bit (Data EEPROM is not write-protected) 
config EBTR0 = OFF      // Table Read Protection bit (Block 0 (000200-0007FFh) not protected from table reads executed in other blocks) 
config EBTR1 = OFF      // Table Read Protection bit (Block 1 (000800-000FFFh) not protected from table reads executed in other blocks) 
config EBTRB = OFF      // Boot Block Table Read Protection bit (Boot block (000000-0001FFh) is not protected from table reads executed in other blocks) 
#endif

include "init_h.bas"
include "bitdefs.bas"

public sub PIC_Init()
    INTCON = 0     // disable interrupts
    INTCON2 = $F5
    INTCON3 = $C0
    PIE1 = 0
    PIE2 = 0

    OSCTUNE = 0
    OSCCON = OSCCON_INIT
    'RCON.bits(IPEN) = 0  // use legacy interrupt model

  #if (_device = 18F24K20)
    ANSEL  = $00      // configure all ADC inputs for digital I/O
    ANSELH = $00
  #endif

  #if (_device = 18F2520)
    ADCON1 = $0F      // configure all ADC inputs for digital I/O
    CMCON  = $07
  #endif

    LATA   = $00
    TRISA  = $C1      // RA1 output for LED1, RA2 output for LED2, RA3 output to LCD_RS, RA4 output for LCD_RW, RA5 output to LCD_E
    LATB   = $30
    TRISB  = $CF      // RB0-3 are keypad row inputs, RB4,RB5 are keypad COL1,COL2 drivers, RB6,RB7 are used for In-Circuit-Debug
    INTCON2.bits(nRBPU) = 0 // enable PORTB pull-ups for inputs
    LATC   = $00
    TRISC  = $F3      // RC2,RC3 are keypad COL3,COL4 drivers, RC4-RC7 are LCD I/O D4-D7
end sub

end module
