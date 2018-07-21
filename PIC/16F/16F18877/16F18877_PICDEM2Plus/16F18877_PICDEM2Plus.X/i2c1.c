/* 
* File:     i2c1.c
* Target:   PIC16F18877
* Compiler: XC8 v1.45
* IDE:      MPLABX v4.05
*
*/
#include <xc.h>
#include "init.h"
#include "i2c1.h"

void I2C1_Init(unsigned char sync_mode, unsigned char slew) 
{
    PIE3bits.SSP1IE = 0;
    PIE3bits.BCL1IE = 0;
    PIR3bits.SSP1IF = 0;
    PIR3bits.BCL1IF = 0;
    I2C1_SCL = 1; // Set SCL1 (PORTC,3) pin to input
    I2C1_SDA = 1; // Set SDA1 (PORTC,4) pin to input

    SSP1STAT &= 0x3F; // power on state 
    SSP1CON1 = 0x00; // power on state
    SSP1CON2 = 0x00; // power on state
    SSP1CON1 |= sync_mode; // select serial mode 
    SSP1STAT |= slew; // slew rate on/off 

    SSP1CON1bits.SSPEN = 1; // enable synchronous serial port 
}

I2C_Result_t I2C1_Write(unsigned char data_out) 
{
    SSP1BUF = data_out; // write single byte to SSP1BUF
    if (SSP1CON1bits.WCOL) // test if write collision occurred
    {
        return ( E_BUS_COLLISION); // if WCOL bit is set return negative #
    }
    else
    {
        if (((SSP1CON1 & 0x0F) != 0x08) && ((SSP1CON1 & 0x0F) != 0x0B)) //slave mode only 
        {
            SSP1CON1bits.CKP = 1; // release clock line 
            while (!PIR3bits.SSP1IF); // wait until ninth clock pulse received
            if ((!SSP1STATbits.R_W) && (!SSP1STATbits.BF))// if R/W=0 and BF=0, NOT ACK was received
            {
                return ( E_NOT_ACK_ERROR); //Return NACK
            }
        } 
        else if (((SSP1CON1 & 0x0F) == 0x08) || ((SSP1CON1 & 0x0F) == 0x0B)) //master mode only	
        {
            while (SSP1STATbits.BF); // wait until write cycle is complete      
            I2C1_Idle(); // ensure module is idle
            if (SSP1CON2bits.ACKSTAT) // test for ACK condition received
            {
                return ( E_NOT_ACK_ERROR); //Return NACK	
            }
        }
    }
    return ( S_OK); //Return ACK
}

unsigned char I2C1_Read(void) 
{
    if (((SSP1CON1 & 0x0F) == 0x08) || ((SSP1CON1 & 0x0F) == 0x0B)) //master mode only
    {
        SSP1CON2bits.RCEN = 1; // enable master for 1 byte reception
    }
    while (!SSP1STATbits.BF); // wait until byte received  
    return ( SSP1BUF); // return with read byte 
}

I2C_Result_t  I2C1_AckProbe(unsigned char control)
{
    I2C_Result_t  ret;
    
    ret = S_OK;
    
    I2C1_Idle(); // ensure module is idle 
    I2C1_Start(); // initiate START condition
    while (SSP1CON2bits.SEN); // wait until start condition is over 
    if (PIR3bits.BCL1IF) // test for bus collision
    {
        ret = E_BUS_COLLISION; // return with Bus Collision error 
    }
    else
    {
        ret = I2C1_Write(control); 
    }

    I2C1_Stop(); // send STOP condition
    while (SSP1CON2bits.PEN); // wait until stop condition is over         
    if (PIR3bits.BCL1IF) // test for bus collision
    {
        ret = E_BUS_COLLISION; // return with Bus Collision error 
    }
    return ( ret );
}

I2C_Result_t I2C1_AckPolling(unsigned char control) 
{
    I2C1_Idle(); // ensure module is idle 
    I2C1_Start(); // initiate START condition
    while (SSP1CON2bits.SEN); // wait until start condition is over 
    if (PIR3bits.BCL1IF) // test for bus collision
    {
        return ( E_BUS_COLLISION); // return with Bus Collision error 
    }
    else
    {
        if (I2C1_Write(control) == E_BUS_COLLISION) // write byte - R/W bit should be 0
        {
            I2C1_Stop();
            return ( E_WRITE_COLLISION); // set error for write collision
        }

        while (SSP1CON2bits.ACKSTAT) // test for ACK condition received
        {
            I2C1_Restart(); // initiate Restart condition
            while (SSP1CON2bits.RSEN); // wait until re-start condition is over 
            if (PIR3bits.BCL1IF) // test for bus collision
            {
                return ( E_BUS_COLLISION); // return with Bus Collision error 
            }
            if (I2C1_Write(control) == E_BUS_COLLISION) // write byte - R/W bit should be 0
            {
                I2C1_Stop();
                return ( E_WRITE_COLLISION); // set error for write collision
            }
        }
    }

    I2C1_Stop(); // send STOP condition
    while (SSP1CON2bits.PEN); // wait until stop condition is over         
    if (PIR3bits.BCL1IF) // test for bus collision
    {
        return ( E_BUS_COLLISION); // return with Bus Collision error 
    }
    return ( S_OK); // return with no error     
}

static I2C_Result_t I2C1_gets(unsigned char *rdptr, unsigned char length) 
{
    while (length--) // perform getcI2C1() for 'length' number of bytes
    {
        *rdptr++ = I2C1_Read(); // save byte received
        while (SSP1CON2bits.RCEN); // check that receive sequence is over    

        if (PIR3bits.BCL1IF) // test for bus collision
        {
            return ( E_BUS_COLLISION); // return with Bus Collision error 
        }

        if (((SSP1CON1 & 0x0F) == 0x08) || ((SSP1CON1 & 0x0F) == 0x0B)) //master mode only
        {
            if (length) // test if 'length' bytes have been read
            {
                SSP1CON2bits.ACKDT = 0; // set acknowledge bit state for ACK        
                SSP1CON2bits.ACKEN = 1; // initiate bus acknowledge sequence
                while (SSP1CON2bits.ACKEN); // wait until ACK sequence is over 
            }
        }

    }
    return ( S_OK); // last byte received so don't send ACK      
}

I2C_Result_t I2C1_SequentialRead(unsigned char control, unsigned short address, unsigned char *rdptr, unsigned char length) 
{
    I2C_Result_t ret;
    
    ret = S_OK;
    I2C1_Idle(); // ensure module is idle
    I2C1_Start(); // initiate START condition
    while (SSP1CON2bits.SEN); // wait until start condition is over 
    if (PIR3bits.BCL1IF) // test for bus collision
    {
        return ( E_BUS_COLLISION); // return with Bus Collision error 
    }
    else
    {
        if (I2C1_Write(control)) // write 1 byte 
        {
            I2C1_Stop();
            return ( E_WRITE_COLLISION); // set error for write collision
        }

        //I2C1_Idle();                    // ensure module is idle
        if (!SSP1CON2bits.ACKSTAT) // test for ACK condition, if received
        {
            if (ret = I2C1_Write(address>>8)) // write word address for EEPROM
            {
                I2C1_Stop();
                return (ret);
            }
            if (ret = I2C1_Write(address&0xFFu)) // write word address for EEPROM
            {
                I2C1_Stop();
                return (ret);
            }

            //I2C1_Idle();                  // ensure module is idle
            if (!SSP1CON2bits.ACKSTAT) // test for ACK condition received
            {
                I2C1_Restart(); // generate I2C bus restart condition
                while (SSP1CON2bits.RSEN); // wait until re-start condition is over 
                if (I2C1_Write(control + 1u))// WRITE 1 byte - R/W bit should be 1 for read
                {
                    I2C1_Stop();
                    return ( E_WRITE_COLLISION); // set error for write collision
                }

                //I2C1_Idle();                // ensure module is idle
                if (!SSP1CON2bits.ACKSTAT)// test for ACK condition received
                {
                    if (I2C1_gets(rdptr, length))// read in multiple bytes
                    {
                        return ( E_BUS_COLLISION); // return with Bus Collision error
                    }

                    I2C1_NotAck(); // send not ACK condition
                    while (SSP1CON2bits.ACKEN); // wait until ACK sequence is over 
                    I2C1_Stop(); // send STOP condition
                    while (SSP1CON2bits.PEN); // wait until stop condition is over 
                    if (PIR3bits.BCL1IF) // test for bus collision
                    {
                        return ( E_BUS_COLLISION); // return with Bus Collision error 
                    }
                }
                else
                {
                    I2C1_Stop();
                    return ( E_NOT_ACK_ERROR); // return with Not Ack error
                }
            }
            else
            {
                I2C1_Stop();
                return ( E_NOT_ACK_ERROR); // return with Not Ack error
            }
        }
        else
        {
            I2C1_Stop();
            return ( E_NOT_ACK_ERROR); // return with Not Ack error
        }
    }
    return ( S_OK); // return with no error
}

static I2C_Result_t I2C1_puts(unsigned char *wrptr, unsigned char length) 
{
    I2C_Result_t temp;
    while (length) // transmit data until null character 
    {
        if (SSP1CON1bits.SSPM3) // if Master transmitter then execute the following
        {
            temp = I2C1_Write(*wrptr);
            if (temp != S_OK)
            {
                return ( temp);
            }
            //if ( I2C1_Write( *wrptr ) )   // write 1 byte
            //{
            //  return ( E_WRITE_COLLISION);              // return with write collision error
            //}
            //I2C1_Idle();                  // test for idle condition
            //if ( SSP1CON2bits.ACKSTAT )   // test received ack bit state
            //{
            //  return ( E_NOT_ACK_ERROR);              // bus device responded with  NOT ACK
            //}                             // terminate putsI2C1() function
        }
        else // else Slave transmitter
        {
            PIR3bits.SSP1IF = 0; // reset SSP1IF bit
            SSP1BUF = *wrptr; // load SSP1BUF with new data
            SSP1CON1bits.CKP = 1; // release clock line 
            while (!PIR3bits.SSP1IF); // wait until ninth clock pulse received

            if ((SSP1CON1bits.CKP) && (!SSP1STATbits.BF))// if R/W=0 and BF=0, NOT ACK was received
            {
                return ( E_NOT_ACK_ERROR); // terminate PutsI2C1() function
            }
        }

        wrptr++; // increment pointer
        length--;
        
    } // continue data writes until null character

    return ( S_OK );
}

I2C_Result_t I2C1_SequentialWrite(unsigned char control, unsigned short address, unsigned char *wrptr, unsigned char length) 
{
    I2C_Result_t ret;

    ret = S_OK;
    I2C1_Idle(); // ensure module is idle
    I2C1_Start(); // initiate START condition
    while (SSP1CON2bits.SEN); // wait until start condition is over 
    if (PIR3bits.BCL1IF) // test for bus collision
    {
        return ( E_BUS_COLLISION); // return with Bus Collision error 
    }
    else
    {
        if (I2C1_Write(control)) // write 1 byte - R/W bit should be 0
        {
            I2C1_Stop();
            return ( E_WRITE_COLLISION); // return with write collision error
        }

        //I2C1_Idle();                    // ensure module is idle
        if (!SSP1CON2bits.ACKSTAT) // test for ACK condition, if received 
        {
            if (ret = I2C1_Write(address>>8)) // write word address for EEPROM
            {
                I2C1_Stop();
                return (ret);
            }
            if (ret = I2C1_Write(address&0xFFu)) // write word address for EEPROM
            {
                I2C1_Stop();
                return (ret);
            }


            //I2C1_Idle();                  // ensure module is idle
            if (!SSP1CON2bits.ACKSTAT) // test for ACK condition, if received
            {
                ret = I2C1_puts(wrptr, length);
                if (ret != S_OK) 
                {
                    I2C1_Stop();
                    return (ret); // bus device responded possible error
                }
            }
            else
            {
                I2C1_Stop();
                return ( E_NOT_ACK_ERROR); // return with Not Ack error
            }
        }
        else
        {
            I2C1_Stop();
            return ( E_NOT_ACK_ERROR); // return with Not Ack error
        }
    }

    //I2C1_Idle();                      // ensure module is idle
    I2C1_Stop(); // send STOP condition
    while (SSP1CON2bits.PEN); // wait until stop condition is over 
    if (PIR3bits.BCL1IF) // test for Bus collision
    {
        return ( E_BUS_COLLISION); // return with Bus Collision error 
    }
    return ( S_OK ); // return with no error
}


I2C_Result_t I2C1_Transaction(unsigned char control, unsigned char *pWrite, unsigned char Write_length, unsigned char *pRead, unsigned char Read_length) 
{
    I2C_Result_t ret;
    
    ret = S_OK;
    I2C1_Idle(); // ensure module is idle
    I2C1_Start(); // initiate START condition
    while (SSP1CON2bits.SEN); // wait until start condition is over 
    if (PIR3bits.BCL1IF) // test for bus collision
    {
        return ( E_BUS_COLLISION); // return with Bus Collision error 
    }
    else
    {
        if (I2C1_Write(control)) // write 1 byte 
        {
            I2C1_Stop();
            return ( E_WRITE_COLLISION); // set error for write collision
        }

        //I2C1_Idle();                    // ensure module is idle
        if (!SSP1CON2bits.ACKSTAT) // test for ACK condition, if received
        {
            if((pWrite) && (Write_length))
            {
                do
                {
                    Write_length--;
                    ret = I2C1_Write(pWrite[Write_length]);
                    if(ret != S_OK)
                    {
                        I2C1_Stop();
                        return (ret);
                    }
                } while(Write_length);
            }

            //I2C1_Idle();                  // ensure module is idle
            if (!SSP1CON2bits.ACKSTAT) // test for ACK condition received
            {
                if((pRead) && (Read_length))
                {
                    if (pWrite)
                    {
                        I2C1_Restart(); // generate I2C bus restart condition
                        while (SSP1CON2bits.RSEN); // wait until re-start condition is over 
                    }
                    if (I2C1_Write(control + 1u))// WRITE 1 byte - R/W bit should be 1 for read
                    {
                        I2C1_Stop();
                        return ( E_WRITE_COLLISION); // set error for write collision
                    }

                    //I2C1_Idle();                // ensure module is idle
                    if (!SSP1CON2bits.ACKSTAT)// test for ACK condition received
                    {
                        if (I2C1_gets(pRead, Read_length))// read in multiple bytes
                        {
                            return ( E_BUS_COLLISION); // return with Bus Collision error
                        }

                        I2C1_NotAck(); // send not ACK condition
                        while (SSP1CON2bits.ACKEN); // wait until ACK sequence is over 
                        I2C1_Stop(); // send STOP condition
                        while (SSP1CON2bits.PEN); // wait until stop condition is over 
                        if (PIR3bits.BCL1IF) // test for bus collision
                        {
                            return ( E_BUS_COLLISION); // return with Bus Collision error 
                        }
                    }
                    else
                    {
                        I2C1_Stop();
                        return ( E_NOT_ACK_ERROR); // return with Not Ack error
                    }
                }
            }
            else
            {
                I2C1_Stop();
                return ( E_NOT_ACK_ERROR); // return with Not Ack error
            }
        }
        else
        {
            I2C1_Stop();
            return ( E_NOT_ACK_ERROR); // return with Not Ack error
        }
    }
    return ( S_OK); // return with no error
}