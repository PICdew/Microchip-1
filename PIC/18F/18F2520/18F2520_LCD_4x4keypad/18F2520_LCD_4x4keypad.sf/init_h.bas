//
// File:   init_h.bas
// Author:
// Target: PIC18F24K20, PIC18F2520
//
Module init_h

//   Specify the System clock frequency in Hz
#define FSYS = 1000000
//   Specify PIC18F internal oscillator fresuency
Public Const OSCCON_INIT = $40

//   Specify the Peripheral clock frequency in Hz
#define FCYC = (FSYS/4)

#define _XTAL_FREQ = FSYS

//   Specify the TIMER0 prescale and keypad matrix debounce count based on the system clock frequency
#if   (FSYS >= 8000000)
Public Const  T0CON_INIT = %11000010 // TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:8
Public Const KP_DEBOUNCE_COUNT = 16
#elseif (FSYS >= 4000000)
Public Const  T0CON_INIT = %11000001 // TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:4
Public Const KP_DEBOUNCE_COUNT = 16
#elseif (FSYS >= 2000000)
Public Const  T0CON_INIT = %11000000 // TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:2
Public Const KP_DEBOUNCE_COUNT = 16
#elseif (FSYS >= 1000000)
Public Const  T0CON_INIT = %11001111 // TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:1
Public Const KP_DEBOUNCE_COUNT = 16
#elseif (FSYS >=  500000)
Public Const  T0CON_INIT = %11001111 // TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:1
Public Const KP_DEBOUNCE_COUNT = 12
#elseif (FSYS >=  250000)
Public Const  T0CON_INIT = %11001111 // TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:1
Public Const KP_DEBOUNCE_COUNT = 8
#elseif (FSYS >=  125000)
Public Const  T0CON_INIT = %11001111 // TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:1
Public Const KP_DEBOUNCE_COUNT = 6
#else
Public Const  T0CON_INIT = %11001111 // TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:1
Public Const KP_DEBOUNCE_COUNT = 3
#endif

End Module
