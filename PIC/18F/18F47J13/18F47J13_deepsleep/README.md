# PIC18F47J13 Deep Sleep Demo
=============================

Initialize the PIC to start with the default INTOSC at 4MHz, change to 8MHz then setup for deep sleep.

Output bits on PORTB are used to indicate status.

RB1 - On wake up asserts early in initialization the deasserts when initialization completes.

RB1 - Indicates failure to enter deep sleep by toggling rapidly until user causes a reset.

RB2 - Toggles on wake from deep sleep caused by the Deep Sleep Watch Dog Timeout.

RB3 - Toggles on wake from deep sleep caused by the INT0 HIGH to LOW edge.
