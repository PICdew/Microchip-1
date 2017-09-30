/*
 * file: usart.h
 * target: PIC16F877A
 *
 */
#ifndef USART_H
#define USART_H
    
#define UARTCKPIN TRISCbits.TRISC6
#define UARTDTPIN TRISCbits.TRISC7

#define SPBRG_AT_MAXIMUM 0
    
#define BRGH_AT_38400  (1)
#define BRGH_AT_19200  (1)
#define BRGH_AT_9600   (1)
#define BRGH_AT_4800   (0)
#define BRGH_AT_2400   (0)

#define SPBRG_AT_38400  (_XTAL_FREQ/((64UL>>(2UL*BRGH_AT_38400)) * 38400UL) - 1)
#if !((SPBRG_AT_38400 > 0) && (SPBRG_AT_38400 < 256))
#error Baud rate 38400 invalid
#endif
#define SPBRG_AT_19200  (_XTAL_FREQ/((64UL>>(2UL*BRGH_AT_19200)) * 19200UL) - 1)
#if !((SPBRG_AT_19200 > 0) && (SPBRG_AT_19200 < 256))
#error Baud rate 19200 invalid
#endif
#define SPBRG_AT_9600   (_XTAL_FREQ/((64UL>>(2UL*BRGH_AT_9600)) *  9600UL) - 1)
#if !((SPBRG_AT_9600 > 0) && (SPBRG_AT_9600 < 256))
#error Baud rate 9600 invalid
#endif
#define SPBRG_AT_4800   (_XTAL_FREQ/((64UL>>(2UL*BRGH_AT_4800)) *  4800UL) - 1)
#if !((SPBRG_AT_4800 > 0) && (SPBRG_AT_4800 < 256))
#error Baud rate 4800 invalid
#endif
#define SPBRG_AT_2400   (_XTAL_FREQ/((64UL>>(2UL*BRGH_AT_2400)) *  2400UL) - 1)
#if !((SPBRG_AT_2400 > 0) && (SPBRG_AT_2400 < 256))
#error Baud rate 2400 invalid
#endif

    
    
    
typedef enum eUART_CONFIG {UART_READ,UART_WRITE,UART_READ_AND_WRITE} UART_CONFIG;
typedef enum eUART_MODE {UART_ASYNC,UART_SYNC_MASTER,UART_SYNC_SLAVE} UART_MODE;
typedef enum eUART_BAUD {UART_BAUD_NONE=0,UART_BAUD_MAXIMUM,UART_BAUD_38400,UART_BAUD_19200,UART_BAUD_9600,UART_BAUD_4800,UART_BAUD_2400} UART_BAUD;
    
    
extern unsigned char OERRcounter;
extern unsigned char FERRcounter;
    
    
extern void UART_Init(UART_BAUD baudselect, UART_CONFIG conf, UART_MODE mode, unsigned char nine);
extern void UART_Write(unsigned char data);
extern unsigned char UART_TX_Empty( void );
extern unsigned char UART_Data_Ready( void );
extern unsigned char UART_Read(unsigned char *buffer);
    
#endif
