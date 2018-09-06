/* 
 * File:     i2c1.h
 * Target:   PIC16F18877
 * Compiler: XC8 v1.45
 * IDE:      MPLABX v4.05
 *
 */

#ifndef I2C1_H
#define I2C1_H

/* SSPCON1 REGISTER */
#define   SSPENB    			0b00100000  	/* Enable serial port and configures SCK, SDO, SDI*/
#define   SLAVE_7   			0b00000110     	/* I2C Slave mode, 7-bit address*/
#define   SLAVE_10  			0b00000111    	/* I2C Slave mode, 10-bit address*/
#define   MASTER    			0b00001000     	/* I2C Master mode */
#define   MASTER_FIRMW			0b00001011		//I2C Firmware Controlled Master mode (slave Idle)
#define   SLAVE_7_STSP_INT 		0b00001110		//I2C Slave mode, 7-bit address with Start and Stop bit interrupts enabled
#define   SLAVE_10_STSP_INT 	0b00001111		//I2C Slave mode, 10-bit address with Start and Stop bit interrupts enabled

/* SSPSTAT REGISTER */
#define   SLEW_OFF  			0b10000000  	/* Slew rate disabled for 100kHz mode */
#define   SLEW_ON   			0b00000000  	/* Slew rate enabled for 400kHz mode  */

#define I2C1_SCL        TRISCbits.TRISC3
#define I2C1_SDA        TRISCbits.TRISC4

#define I2C1_Clear_Intr_Status_Bit      (PIR3bits.SSP1IF = 0)
#define I2C1_Intr_Status                (PIR3bits.SSP1IF

#define I2C1_Stop()     SSP1CON2bits.PEN=1;while(SSP1CON2bits.PEN)
#define I2C1_Start()    SSP1CON2bits.SEN=1;while(SSP1CON2bits.SEN)
#define I2C1_Restart()  SSP1CON2bits.RSEN=1;while(SSP1CON2bits.RSEN)
#define I2C1_NotAck()   SSP1CON2bits.ACKDT=1, SSP1CON2bits.ACKEN=1;while(SSP1CON2bits.ACKEN)
#define I2C1_Ack()      SSP1CON2bits.ACKDT=0, SSP1CON2bits.ACKEN=1;while(SSP1CON2bits.ACKEN)
#define I2C1_Idle()     while ((SSP1CON2 & 0x1F) | (SSP1STATbits.R_W))
#define I2C1_Close()    SSP1CON1 &=0xDF

typedef enum
{
    S_OK = 0,
    E_BUS_COLLISION,
    E_NOT_ACK_ERROR,
    E_WRITE_COLLISION
} I2C_Result_t;

void I2C1_Init( unsigned char sync_mode, unsigned char slew );
unsigned char I2C1_Read( void );
I2C_Result_t  I2C1_Write( unsigned char data_out );
I2C_Result_t  I2C1_AckProbe(unsigned char control);
I2C_Result_t  I2C1_AckPolling(unsigned char control);
I2C_Result_t  I2C1_SequentialRead(unsigned char control, unsigned short address, unsigned char *rdptr, unsigned char length);
I2C_Result_t I2C1_SequentialWrite(unsigned char control, unsigned short address, unsigned char *wrptr, unsigned char length);
I2C_Result_t I2C1_Transaction(unsigned char control, unsigned char *pWrite, unsigned char Write_length, unsigned char *pRead, unsigned char Read_length);

#endif

