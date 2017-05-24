PIC16F887 Buttons and LCD interface
===================================

PIC assembly language code that runs on the Microchip PICDEM2 Plus (DM163022-1) 

http://www.microchip.com/Developmenttools/ProductDetails.aspx?PartNO=DM163022-1

The application implements a parallel interface to an Hitachi 44780 type LCD 
character modules. The PICDEM2 Plus hardware uses 4-bit data + 3 control 
lines to interface with the LCD module.

The 4-bit interface on some Hitachi 44780 type LCD character modules have not 
been implemented correctly on some of the modules shipped with the PICDEM2 Plus. 
Some of these Novatek 7605 type controllers return the nibbles in the wrong order 
when responding to a status read. This has the consequence is that the example 
code Microchip provides uses wait loops for each byte of command for data sent 
to the LCD module.

The code presented here probes the LCD module to detect this type of module 
and does a proper job of polling the LCD module busy status.

The S2 and S3 buttons are sampled and debounced. 

I have reworked my PICDEM2 Plus to move button S3 from RB0 to RA5. This makes 
the code to drive the four LEDs connected to the RB3,RB2,RB1 and RB0 outputs 
easier to implement.

Adding code to interface with the RS232 serial, I2C EEPROM, ADC input and 
buzzer interfaces is left to others.