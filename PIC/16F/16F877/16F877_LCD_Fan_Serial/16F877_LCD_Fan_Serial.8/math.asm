; ---------------------------
; Math Routines
; ---------------------------
;
#define MATH_ASM
#include "main.inc"
#include "math.inc"

MATH_VAR    UDATA
A_reg:      res     2
B_reg:
D_reg:      res     2
Q_reg:      res     2
mBits:      res     1

MATH_CODE   CODE
;
; Function: uMutiply_16x16
; Input:    A_reg, 16-bit multiplicand
;           B_reg, 16-bit multiplier
;
; Output:   D_reg, 32-bit product
;
; Notes:
;   The B_reg is overwritten by the low 16-bits of the product.
;
uMutiply_16x16:
    banksel mBits
    movlw   d'16'           ; Setup the number of bits to multiply
    movwf   mBits
    clrf    D_reg+2         ; Zero out the product register.
    clrf    D_reg+3
    clrc
    rrf     B_reg+1,F
    rrf     B_reg,F
uM16x16a:
    bnc     uM16x16b
    movf    A_reg,W         ; When CARRY is set then add 
    addwf   D_reg+2,F       ; the multiplicand to the product.
    movf    A_reg+1,W
    skpnc
    incfsz  A_reg+1,W
    addwf   D_reg+3,F
uM16x16b:
    rrf     D_reg+3,F       ; Shift in the CARRY from the add
    rrf     D_reg+2,F       ; and shift the product and multiplier
    rrf     D_reg+1,F       ; right one bit.
    rrf     D_reg+0,F
    decfsz  mBits,f         ; Decrement the bit count and loop
    goto    uM16x16a        ; until multiplication is complete.
    
    return
;
; Function: Bin2BCD
; Input:    A_reg, 16-bit binary
;
; Output:   D_reg, 3 bytes of packed BCD digits
;
Bin2BCD:
    banksel D_reg
    clrf    D_reg+0         ; Clear result
    clrf    D_reg+1
    clrf    D_reg+2
    movlw   D'16'           ; Set bit counter
    movwf   mBits

ConvertBit:
    movlw   h'33'           ; Correct BCD value so that
    addwf   D_reg+0,F       ; subsequent shift yields
    btfsc   D_reg+0,.3      ; correct value.
    andlw   h'f0'
    btfsc   D_reg+0,.7
    andlw   h'0f'
    subwf   D_reg+0,F

    movlw   h'33'
    addwf   D_reg+1,F
    btfsc   D_reg+1,.3
    andlw   h'f0'
    btfsc   D_reg+1,.7
    andlw   h'0f'
    subwf   D_reg+1,F

    rlf     A_reg+0,F       ; Shift out a binary bit
    rlf     A_reg+1,F

    rlf     D_reg+0,F       ; .. and into BCD value
    rlf     D_reg+1,F
    rlf     D_reg+2,F

    decfsz  mBits,F         ; Repeat for all bits
    goto    ConvertBit
    return     

    end
