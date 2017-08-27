/*
 * File:   config.c 
 * Target: PIC24GJ1024GB610
 */
#ifndef __PIC24FJ1024GB610__
#error "Processor setting does not match."
#endif

#pragma config BTMODE = SINGLE          // Boot Mode Configuration bits (Device is in Single Boot (legacy) mode)
#pragma config BWRP = OFF               // Boot Segment Write-Protect bit (Boot Segment may be written)
#pragma config BSS = DISABLED           // Boot Segment Code-Protect Level bits (No Protection (other than BWRP))
#pragma config BSEN = OFF               // Boot Segment Control bit (No Boot Segment)
#pragma config GWRP = OFF               // General Segment Write-Protect bit (General Segment may be written)
#pragma config GSS = DISABLED           // General Segment Code-Protect Level bits (No Protection (other than GWRP))
#pragma config CWRP = OFF               // Configuration Segment Write-Protect bit (Configuration Segment may be written)
#pragma config CSS = DISABLED           // Configuration Segment Code-Protect Level bits (No Protection (other than CWRP))
#pragma config AIVTDIS = ON             // Alternate Interrupt Vector Table bit (Enabled AIVT)
#pragma config BSLIM = 0x1FFF           // Boot Segment Flash Page Address Limit bits (Boot Segment Flash page address  limit)
#pragma config FNOSC = FRC              // Oscillator Source Selection (Internal Fast RC (FRC))
#pragma config PLLMODE = PLL96DIV2      // PLL Mode Selection (96 MHz PLL. (8 MHz input))
#pragma config IESO = OFF               // Two-speed Oscillator Start-up Enable bit (Start up with user-selected oscillator source)
#pragma config POSCMD = HS              // Primary Oscillator Mode Select bits (HS Crystal Oscillator Mode)
#pragma config OSCIOFCN = ON            // OSC2 Pin Function bit (OSC2 is general purpose digital I/O pin)
#pragma config SOSCSEL = ON             // SOSC Power Selection Configuration bits (SOSC is used in crystal (SOSCI/SOSCO) mode)
#pragma config PLLSS = PLL_FRC          // PLL Secondary Selection Configuration bit (PLL is fed by the on-chip Fast RC (FRC) oscillator)
#pragma config IOL1WAY = OFF            // Peripheral pin select configuration bit (Allow multiple reconfigurations)
#pragma config FCKSM = CSECMD           // Clock Switching Mode bits (Clock switching is enabled,Fail-safe Clock Monitor is disabled)
#pragma config WDTPS = PS32768          // Watchdog Timer Postscaler bits (1:32,768)
#pragma config FWPSA = PR128            // Watchdog Timer Prescaler bit (1:128)
#pragma config FWDTEN = ON_SWDTEN       // Watchdog Timer Enable bits (WDT Enabled/Disabled (controlled using SWDTEN bit))
#pragma config WINDIS = OFF             // Watchdog Timer Window Enable bit (Watchdog Timer in Non-Window mode)
#pragma config WDTWIN = WIN25           // Watchdog Timer Window Select bits (WDT Window is 25% of WDT period)
#pragma config WDTCMX = WDTCLK          // WDT MUX Source Select bits (WDT clock source is determined by the WDTCLK Configuration bits)
#pragma config WDTCLK = LPRC            // WDT Clock Source Select bits (WDT uses LPRC)
#pragma config BOREN = SBOREN           // Brown Out Enable bit (Controlled by SBOREN)
#pragma config LPCFG = OFF              // Low power regulator control (No Retention Sleep)
#pragma config DNVPEN = ENABLE          // Downside Voltage Protection Enable bit (Downside protection enabled using ZPBOR when BOR is inactive)
#pragma config ICS = PGD2               // ICD Communication Channel Select bits (Communicate on PGEC1 and PGED1)
#pragma config JTAGEN = OFF             // JTAG Enable bit (JTAG is disabled)
#pragma config BTSWP = OFF              // BOOTSWP Disable (BOOTSWP instruction disabled)
#pragma config ALTCMPI = DISABLE        // Alternate Comparator Input Enable bit (C1INC, C2INC, and C3INC are on their standard pin locations)
#pragma config TMPRPIN = OFF            // Tamper Pin Enable bit (TMPRN pin function is disabled)
#pragma config SOSCHP = OFF             // SOSC High Power Enable bit (valid only when SOSCSEL = 1 (Enable SOSC low power mode)
#pragma config ALTVREF = ALTREFEN       // Alternate Voltage Reference Location Enable bit (VREF+ and CVREF+ on RA10, VREF- and CVREF- on RA9)

