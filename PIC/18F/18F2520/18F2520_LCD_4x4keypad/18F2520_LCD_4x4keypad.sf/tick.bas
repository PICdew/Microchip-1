//
// File:   tick.c
// Author:
//
// Target: PIC18F24K20, PIC18F2520
//
module tick

include "init_h.bas"
include "bitdefs.bas"

//
// Setup TIMER0 to assert an interrupt every 16384 instruction cycles
//
public sub Tick_Init()
    INTCON.bits(TMR0IE) = 0
    T0CON = T0CON_INIT      // TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:64
    TMR0H = 0                // TIMER0 will assert the overflow flag every 256*64 (16384)
    TMR0L = 0
    INTCON.bits(TMR0IF) = 0 // instruction cycles, with a 12MHz oscilator this is 1.365 milliseconds
    INTCON.bits(TMR0IE) = 1
end sub

end module

