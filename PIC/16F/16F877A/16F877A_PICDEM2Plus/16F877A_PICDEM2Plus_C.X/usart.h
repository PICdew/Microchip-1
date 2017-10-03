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
    
#define BRGH_AT_115200 (1)
#define BRGH_AT_57600  (1)
#define BRGH_AT_38400  (1)
#define BRGH_AT_19200  (1)
#define BRGH_AT_9600   (1)
#define BRGH_AT_4800   (1)
#define BRGH_AT_2400   (0)
#define BRGH_AT_1200   (0)

#define SPBRG_AT_115200  (_XTAL_FREQ/((64UL>>(2UL*BRGH_AT_115200)) * 115200UL) - 1)
#if !((SPBRG_AT_115200 > 0) && (SPBRG_AT_115200 < 256))
#error Baud rate 115200 invalid
#endif
#define SPBRG_AT_57600  (_XTAL_FREQ/((64UL>>(2UL*BRGH_AT_57600)) * 57600UL) - 1)
#if !((SPBRG_AT_57600 > 0) && (SPBRG_AT_57600 < 256))
#error Baud rate 57600 invalid
#endif
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
#define SPBRG_AT_1200   (_XTAL_FREQ/((64UL>>(2UL*BRGH_AT_1200)) *  1200UL) - 1)
#if !((SPBRG_AT_1200 > 0) && (SPBRG_AT_1200 < 256))
#error Baud rate 1200 invalid
#endif

    
    
    
typedef enum eUSART_CONFIG {USART_READ,USART_WRITE,USART_READ_AND_WRITE} USART_CONFIG;
typedef enum eUSART_MODE {USART_ASYNC,USART_SYNC_MASTER,USART_SYNC_SLAVE} USART_MODE;
typedef enum eUSART_BAUD {USART_BAUD_NONE=0,USART_BAUD_MAXIMUM,USART_BAUD_115200,USART_BAUD_57600,USART_BAUD_38400,USART_BAUD_19200,USART_BAUD_9600,USART_BAUD_4800,USART_BAUD_2400,USART_BAUD_1200} USART_BAUD;
typedef enum eUSART_9TH_BIT {USART_9TH_BIT_OFF,USART_9TH_BIT_ON} USART_9TH_BIT;
    
    
extern volatile unsigned char OERRcounter;
extern volatile unsigned char FERRcounter;
    
    
extern void USART_Init(USART_BAUD baudselect, USART_CONFIG conf, USART_MODE mode, USART_9TH_BIT nineth_bit);
extern void USART_Write(unsigned char data);
extern void USART_WriteConstString(const unsigned char *pBuffer);
void USART_WriteString(unsigned char *pBuffer);
extern unsigned char USART_TX_Empty( void );
extern unsigned char USART_Data_Ready( void );
extern unsigned char USART_Read(unsigned char *buffer);
    
#endif
