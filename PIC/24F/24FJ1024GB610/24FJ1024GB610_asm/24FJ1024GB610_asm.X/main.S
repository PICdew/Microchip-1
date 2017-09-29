    .nolist
    .title " Sample PIC24FJ1024GB610 Assembler Source Code"
    .sbttl " PORTA bit pulser"
    .psize 1000,132
    .list
;   
; File: main.s
; Target: PIC24FJ1024GB610
; IDE: MPLABX v4.00
; Compiler: XC16 v1.32B
;   
; Description:
;   This is a simple "hello world" demo
;   it pulses the bits on PORTA from 
;   bit 0 to bit 7.
;   
    .include "p24Fxxxx.inc"
    .text
;
; The assembly language configuration words.
;
    config  __FBOOT,(BTMODE_SINGLE)
    config  __FSEC,(BWRP_OFF & BSS_OFF & BSEN_OFF & GWRP_OFF & GSS_OFF & CWRP_OFF & CSS_DIS & AIVTDIS_ENABLE)
    config  __FBSLIM,(0x1FFF)
    config  __FOSCSEL,(FNOSC_FRC & PLLMODE_PLL96DIV2 & IESO_OFF)
    config  __FOSC,(POSCMD_HS & OSCIOFCN_ON & SOSCSEL_ON & PLLSS_PLL_FRC & IOL1WAY_OFF & FCKSM_CSECMD)
    config  __FWDT,(WDTPS_PS32768 & FWPSA_PR128 & SWON & WINDIS_OFF & PS25_0 & WDTCMX_WDTCLK & WDTCLK_LPRC)
    config  __FPOR,(SWC & LPCFG_OFF & DNVPEN_ENABLE)
    config  __FICD,(PGX2 & JTAGEN_ON & BTSWP_OFF)
    config  __FDEVOPT1,(ALTCMPI_DISABLE & TMPRPIN_OFF & SOSCHP_OFF & ALTVREF_ALTREFEN)

    .global __reset 
__reset: 
    mov     #__SP_init,w15      ; Initalize the Stack Pointer 
    mov     #__SPLIM_init,w0    ; Initialize the Stack Pointer Limit Register 
    mov     w0, SPLIM 
    nop                         ; Add NOP to follow SPLIM initialization 
    
    call    _wreg_init          ; Set all woring registers to zero 
    
    call    _PIC_init           ; Initialize this PIC 
    
    mov     #0xFF00,w0          ; Set LED on PORTA pins as outputs 
    and     TRISA               ; Make PORTA bits <7:0> outputs
    and     ANSA                ; Make PORTA bits <7:0> digital I/O
    
;   
; Do a simple "hello world" bit pulser 
;   
    clr.b   LATA
    bset    LATA,#0
HelloLoop:
    call    delay 
    rlnc.b  LATA
   
    bra     HelloLoop 
;   
; Delay loop 
;   
delay: 
    mov     #0xffff,w6 
dloop: 
    nop
    nop
    nop
    nop
    dec     w6,w6 
    cp0     w6 
    bra     nz,dloop 
    return 
;   
; Initialize W registers to zero 
;   
_wreg_init: 
    clr     w0 
    mov     w0,w14 
    repeat  #12 
    mov     w0,[++w14] 
    clr     w14 
    return 
    
;   
; Initialize this PIC 
;   
_PIC_init: 
    mov     #0,w0 
    mov.w   w0,CLKDIV           ; Set for default clock operations 
    
    bset    INTCON1,#NSTDIS     ; Disable interrupt nesting 
    
    return 

    .end
