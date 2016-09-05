# PIC18F4520 homework seven segment LED
=======================================

This is one way to complete the generic homework assignment
common in courses on PIC programming. This work is often
assigned in introductory courses. Students may be using MPLAB for 
the first time. It is also common for the students to be learning
about the PROTEUS simulation environment as well.

This example has a single digit 7-segment LED display connected to
PORTB, bits 6 to 0 and a push button switch connected PORTC, bit 0.

The application detects a change of the push button switch then
changes the decimal digit shown on the 7-segment LED in sequence:
0,1,2,3,4,5,6,7,8,9 for each press of the button.

The push button switch is pressed when the input bit is zero and
released when the input is one.

An LED segment is lighted when the output bit is one and is
dark when the output bit is zero,

This implementation uses TIMER0 in 8-bit mode with a 1:8 clock prescale.
Using the internal 8MHz oscillator one millisecond of real time will
have passed when TIMER0 has counted 250 times.

The push button switch input is considered stable when the 
input has not changed for at least 20 of these one millisecond
intervals.
