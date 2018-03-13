//
// File:   tick.c
// Author:
//
// Target: PIC18F24K20, PIC18F2520
//
Module tick

Include "init_h.bas"
Include "bitdefs.bas"

//
// Setup TIMER0 to assert an interrupt every 1.024 milliseconds
//
Public Sub Tick_Init()
    INTCON.bits(TMR0IE) = 0
    T0CON = T0CON_INIT      // TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale as required
    TMR0H = 0               // TIMER0 will assert the overflow flag every 1.024 milliseconds
    TMR0L = 0
    INTCON.bits(TMR0IF) = 0 
    INTCON.bits(TMR0IE) = 1
End Sub

End Module

