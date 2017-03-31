# PIC18F4550 for LCD module, 3x4 keypad and 8 channels of ADC
=============================================================

This is one way to complete a homework assignment that implements
much of the elemental functions to interface an Hitachi HD44780
LCD module for ASCII character display, a 3x4 telephone style
keypad and 8 ADC channels to convert extern 0-5 volt analog
signal inputs.


Development hardware:

Microchip DM163022-1, PICDEM2+v2.0 with PIC18F4550, LCD module,
and a Multicomp Keypad, 3 × 4 Array, P/N: MCAK304NBWB.


Operation:

After Power On Reset the application name and version is displayed
along with the contents of the LCD character generator RAM.

Press any key on the keypad and the message "Key Pressed :" is displayed.
Also when keys 0 to 7 are pressed the ADC value is displayed for
analog inputs AN0 to AN7.

See:

http://www.microchip.com/forums/FindPost/979462

Also:

http://www.microchip.com/forums/FindPost/978149
http://www.microchip.com/forums/FindPost/978369
http://www.microchip.com/forums/FindPost/979382
http://www.microchip.com/forums/FindPost/981970
http://www.microchip.com/forums/FindPost/982425
