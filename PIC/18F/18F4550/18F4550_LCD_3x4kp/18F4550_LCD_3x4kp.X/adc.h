/*
 * File:   adc.h
 * Author: 
 * Target: PIC18F4550
 *
 */
#ifndef ADC_H
#define ADC_H

void ADC_Init(void);
unsigned int ADC_ReadChannel(unsigned char Channel);

#endif
