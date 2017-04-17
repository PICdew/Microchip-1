; ---------------------------
; RPM Routines
; ---------------------------
;
#ifndef RPM_INC
#define RPM_INC
#ifdef  RPM_ASM
#define ExtSymbol   global
#else
#define ExtSymbol   extern
#endif
;
; Declare the public symbols
;
    ExtSymbol   Rpm_Init
    ExtSymbol   Rpm_Status
    ExtSymbol   Rpm_Start
    ExtSymbol   Rpm_PulseCount
    ExtSymbol   Rpm_CountTimeout

; end of public symbols
#undefine ExtSymbol
;
; 
;
; The RPM count period is 250 system ticks.
; A system tick is 1.024 milliseconds, 250 
; ticks is 250 * 1.024 or 256 milliseconds.
;
; To convert Rpm_PulseCount to RPMs we use this forumla:
;
; RPM = ((Rpm_PulseCount / Pulses per revolution) / Pulse count period in milliseconds) * Milliseconds in one minute)
;
; For fan P/N:AFB0712VHB-F00 there are 2 pulses per revolution.
; RPM = ((Rpm_PulseCount / 2) / 256) * 60000)
;     = ((Rpm_PulseCount / 256) * 30000)
;     = ( Rpm_PulseCount * 30000 / 256 )
;
; For fan P/N:THA0412BN there are 4 pulses per revolution.
; RPM = ((Rpm_PulseCount / 4) / 256) * 60000)
;     = ((Rpm_PulseCount / 256) * 15000)
;     = ((Rpm_PulseCount * 15000) / 256 )
;
; When the fan spins at 20520 RPM it produces 342 revolutions in one second.
; At 4 pulses per revolution this is at most 1368 pulses in one second.
; This gives at most 351 counts in 256 milliseconds.
;
; The maximum product we expect is 15000 * 351, or 5265000. This fits in 24-bits.
; 
;
#define RPM_COUNT_PERIOD (D'250')

#endif