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
;
; Function: Uart_Init
; Description:
;   Setup the UART for asynchronous serial communication at
;   at 9600 baud, 8-Data bits, No parity, 1-Stop bit
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  nothing
;
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
;**********************************************************************
; Function: Uart_Getc
; Description:
;   Wait for the the UART transmitter to be ready
;   then sned the character in the WREG
;
; Inputs:   WREG = 8-bit value to send to the UART
;
; Outputs:  none
;
; Returns:  nothing
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
;**********************************************************************
; Function: Uart_GetcStatus
; Description:
;   Get status of UART receiver
;   Returns non-ZERO when character is available
;
; Inputs:   none
;
; Outputs:  none
;
; Returns:  ZERO statis flag, WREG is changed.
;
Uart_GetcStatus:
    banksel PIR1
    movf    PIR1,W
    andlw   (1<<RCIF)
    return
;
;**********************************************************************
; Function: Uart_Getc
; Description:
;   Wait for a character to arrive at the UART
;   then return the character in the WREG
;
; Inputs:   none
;
; Outputs:  WREG = 8-bit value received from the UART
;
; Returns:  nothing
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
;**********************************************************************
; Function: Uart_PutHex
; Description:
;   Writes two ASCII character of the
;   hexadecimal value in thw WREG register.
;
; Inputs:   WREG = 8-bit value to convert to ASCII hex and send to the UART
;
; Outputs:  none
;
; Returns:  nothing
;
Uart_PutHex:
        banksel Uart_pszRomStr
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
        banksel Uart_pszRomStr
        movf    Uart_pszRomStr,W
        return
;
;**********************************************************************
; Function: Uart_PutDec
; Description:
;   Writes two ASCII character of the
;   BCD value in the WREG register.
;
; Inputs:   WREG = 8-bit BCD value to convert to ASCII and send to the LCD
;           CARRY = 1 suppress zero of MSD
;           DIGIT_CARRY = 1 suppress zero of LSD
;
; Outputs:  none
;
; Returns:  When either BCD digit is not zero then CARRY and DIGIT_CARRY are cleared
;
; Notes:
;   When sending multiple pairs of BCD digits with zero suppression start with
;   CARRY and DIGIT_CARRY set to one. For the last BCD digit pair always clear
;   the DIGIT_CARRY to zero. This will display the last digit when when the 
;   entire BCD number is all zeros.
;
;
Uart_PutDecLSD:
        banksel Uart_pszRomStr
        movwf   Uart_pszRomStr      ; save digits to send
        swapf   STATUS,W            ; save zero suppression flags
        movwf   Uart_pszRomStr+1
        goto    Uart_PutDecLSDonly
        
Uart_PutDec:
        banksel Uart_pszRomStr
        movwf   Uart_pszRomStr      ; save digits to send
        swapf   STATUS,W            ; save zero suppression flags
        movwf   Uart_pszRomStr+1
        swapf   Uart_pszRomStr,W
        andlw   0x0F
        btfsc   Uart_pszRomStr+1,4
        skpz                        ; Skip if digit is zero
        goto    Uart_PutDecMSDnz
        iorlw   ' '                 ; convert leading zero to space
        goto    Uart_PutDecMSDzero
Uart_PutDecMSDnz:
        bcf     Uart_pszRomStr+1,4  ; digit not zero so stop suppressing zeros in MSD
        bcf     Uart_pszRomStr+1,5  ; digit not zero so stop suppressing zeros in LSD
        iorlw   '0'                 ; Convert BCD digit to ASCII number
Uart_PutDecMSDzero:
        call    Uart_Putc
        banksel Uart_pszRomStr
        
Uart_PutDecLSDonly:
        movf    Uart_pszRomStr,W
        andlw   0x0F
        btfsc   Uart_pszRomStr+1,5  ; Skip when leading zero suppression is off
        skpz                        ; Skip if digit is zero
        goto    Uart_PutDecLSDnz
        movlw   ' '                 ; convert leading zero to space
        goto    Uart_PutDecLSDzero
Uart_PutDecLSDnz:
        bcf     Uart_pszRomStr+1,4  ; digit not zero so stop suppressing zeros in MSD
        bcf     Uart_pszRomStr+1,5  ; digit not zero so stop suppressing zeros in LSD
        iorlw   '0'                 ; Convert BCD digit to ASCII number
Uart_PutDecLSDzero:
        call    Uart_Putc
        banksel Uart_pszRomStr

        swapf   Uart_pszRomStr+1,W   ; Return state of zero suppression flags
        movwf   STATUS
        swapf   Uart_pszRomStr,F     ; Return 
        swapf   Uart_pszRomStr,W
        return
;
;**********************************************************************
; Function: Uart_Putrs
; Description:
;   This routine writes a string of bytes to the
;   UART Asynchronous serial port.
;
; Inputs:   Uart_pszRomStr: pointer to string
;
; Outputs:  none
;
; Returns:  nothing
;
Uart_Putrs:
    call    Uart_TableLookUp
    pagesel Uart_Putrs
    iorlw   0
    skpnz
    return
    call    Uart_Putc
    banksel Uart_pszRomStr
    incf    Uart_pszRomStr,F
    skpnz
    incf    Uart_pszRomStr+1,F
    goto    Uart_Putrs
    
Uart_TableLookUp:
    banksel Uart_pszRomStr
    movfw   Uart_pszRomStr+1
    movwf   PCLATH
    movfw   Uart_pszRomStr
    movwf   PCL

    end
