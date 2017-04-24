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
    ExtSymbol   Isr_FanPulseCount   
    ExtSymbol   Rpm_CountTimeout    
    ExtSymbol   Rpm_FanPulseCount   
    ExtSymbol   Fan_PulseNoiseFilter

; end of public symbols
#undefine ExtSymbol
;
;**********************************************************************
; RPM constants
;
; The RPM count period is 250 system ticks.
; A system tick is 1.024 milliseconds, 250 
; ticks is 250 * 1.024 or 256 milliseconds.
;
; To convert Isr_FanPulseCount to RPMs we use this forumla:
;
; RPM = ((Isr_FanPulseCount / Pulses per revolution) / Pulse count period in milliseconds) * Milliseconds in one minute)
;
; For fan P/N:AFB0712VHB-F00 there are 2 pulses or 4 edges per revolution.
; RPM = ((Isr_FanPulseCount / 2) / 256) * 60000)
;     = ((Isr_FanPulseCount / 256) * 30000)
;     = ( Isr_FanPulseCount * 30000 / 256 )
;
; For fan P/N:THA0412BN there are 4 pulses or 8 edges per revolution.
; RPM = ((Isr_FanPulseCount / 4) / 256) * 60000)
;     = ((Isr_FanPulseCount / 256) * 15000)
;     = ((Isr_FanPulseCount * 15000) / 256 )
;
; When the fan spins at 20520 RPM it produces 342 revolutions in one second.
; At 4 edges per revolution this is at most 1368 counts in one second.
; This gives at most 351 counts in 256 milliseconds.
;
; The maximum product we expect is 15000 * 351, or 5265000. This fits in 24-bits.
; 
;
#define MILLISECONDS_IN_ONE_MINUTE (D'60000')
#define SYSTEM_TICKS_IN_256MS (D'250')
#define NUMBER_OF_SAMPLE_PERIODS (D'5')
#define EDGES_PER_REVOLUTION (D'4')
#define FAN_PULSE_FILTER_SYSTEM_TICKS (D'7')
#define RPM_COUNT_PERIOD (SYSTEM_TICKS_IN_256MS*NUMBER_OF_SAMPLE_PERIODS)
#define K1 (MILLISECONDS_IN_ONE_MINUTE/(NUMBER_OF_SAMPLE_PERIODS*EDGES_PER_REVOLUTION))

#endif