; ---------------------------
; Uart Routines
; ---------------------------
;
#define UART_ASM
#include "main.inc"
#include "uart.inc"

UART_VAR    UDATA
Uart_pszRomStr      res     2

UART_CODE   CODE

Uart_Init:
    banksel PIE1                ; Disable UART interrupts
    bcf     PIE1,RCIE
    bcf     PIE1,TXIE

    banksel RCSTA
    clrf    RCSTA               ; Reset reciever
    banksel TXSTA
    clrf    TXSTA               ; Reset tarnsmitter
    bsf     TRISC,TRISC6        ; Make UART pins inputs
    bsf     TRISC,TRISC7
#if ( ((FCYC/(BAUD_RATE*4))-1) < d'256' )
  #if ( ((FCYC/(BAUD_RATE*4))-1) < 1 )
    error Baudrate out of range
  #else
    bsf     TXSTA,BRGH          ; Use high speed baudrate divisor
    movlw   (FCYC/(BAUD_RATE*4))-1
  #endif
#else
  #if ( ((FCYC/(BAUD_RATE*16))-1) < d'256' )
    bcf     TXSTA,BRGH          ; Use low speed baudrate divisor
    movlw   (FCYC/(BAUD_RATE*16))-1
  #else
    error Baudrate out of range
  #endif
#endif
    movwf   SPBRG               ; Set baudrate
    bsf     TXSTA,TXEN
    banksel RCSTA
    bsf     RCSTA,CREN
    bsf     RCSTA,SPEN
    bcf     PIR1,RCIF
    bcf     PIR1,TXIE
#ifdef UART_ISR_ENABLED
    banksel PIE1                ; enable UART interrupts
    bsf     PIE1,RCIE
    bsf     PIE1,TXIE
#endif
    return
;
; Wait for the the UART transmitter to be ready
; then sned the character in the WREG
;
Uart_Putc:
    banksel TXSTA
Uart_PutcWait:
    btfss   TXSTA,TRMT
    goto    Uart_PutcWait
    banksel TXREG
    movwf   TXREG
    return
;
; Get status of UART receiver
; Returns non-ZERO when character is available
;
Uart_GetcStatus:
    banksel PIR1
    movf    PIR1,W
    andlw   (1<<RCIF)
    return
;
; Wait for a character to arrive at the UART
; then return the character in the WREG
;
Uart_Getc:
    banksel PIR1
Uart_GetcWait:
    btfss   PIR1,RCIF
    goto    Uart_GetcWait
    btfsc   RCSTA,OERR
    goto    Uart_GetcOERR
    btfsc   RCSTA,FERR
    goto    Uart_GetcFERR
    movf    RCREG,W
    return
;
; Handle overrun error
;
Uart_GetcOERR:
    bcf     RCSTA,CREN
    bsf     RCSTA,CREN
    movf    RCREG,W
    movf    RCREG,W
    movf    RCREG,W
    goto    Uart_GetcWait
;
; Handle framing error
;
Uart_GetcFERR:
    movf    RCREG,W
    goto    Uart_GetcWait

;
; Function Name:  Uart_PutHex
; Return Value:   void
; Parameters:     W = 8-bit value to send to the UART
; Description:    Writes two ASCII character of the
;                 hexadecimal value in thw W register.
;
Uart_PutHex:
        movwf   Uart_pszRomStr
        swapf   Uart_pszRomStr,W
        call    Uart_PutHexNibble
        movf    Uart_pszRomStr,W
Uart_PutHexNibble:
        andlw   0x0F
        addlw   0x06
        btfsc   STATUS,DC
        addlw   'A'-'0'-d'10'
        addlw   '0'-d'6'   
        call    Uart_Putc
        movf    Uart_pszRomStr,W
        return
;
; Function Name:  Uart_Putrs
; Return Value:   void
; Parameters:     Uart_pszRomStr: pointer to string
; Description:    This routine writes a string of bytes to the
;                 UART Asynchronous serial port.
;
Uart_Putrs:
    call    Uart_TableLookUp
    iorlw   0
    skpnz
    return
    call    Uart_Putc
    incf    Uart_pszRomStr,F
    skpnz
    incf    Uart_pszRomStr+1,F
    goto    Uart_Putrs
    
Uart_TableLookUp:
    movfw   Uart_pszRomStr+1
    movwf   PCLATH
    movfw   Uart_pszRomStr
    movwf   PCL

    end
