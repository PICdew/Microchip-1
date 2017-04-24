; ---------------------------
; Uart Routines
; ---------------------------
;
#ifndef UART_INC
#define UART_INC
#ifdef  UART_ASM
#define ExtSymbol   global
#else
#define ExtSymbol   extern
#endif
;
; Declare the public symbols
;
    ExtSymbol   Uart_Init
    ExtSymbol   Uart_Putc
    ExtSymbol   Uart_Getc
    ExtSymbol   Uart_GetcStatus
    ExtSymbol   Uart_PutHex
    ExtSymbol   Uart_PutDec
    ExtSymbol   Uart_PutDecLSD
    ExtSymbol   Uart_Putrs
    ExtSymbol   Uart_pszRomStr

; end of public symbols
#undefine ExtSymbol

;
; 
;
#define CR (D'13')
#define LF (D'10')
#define BAUD_RATE (D'9600')

#endif