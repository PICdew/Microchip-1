/*
 * File:   pwm.h
 * Author: 
 * Target: PIC18F4550
 *
 */
#ifndef PWM_H
#define PWM_H

void PWM_Init(void);
void PWM_SetPwm1DutyCycle(unsigned char percent);
void PWM_SetPwm2DutyCycle(unsigned char percent);

#endif
