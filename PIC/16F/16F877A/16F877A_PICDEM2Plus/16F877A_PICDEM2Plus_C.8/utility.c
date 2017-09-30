/* 
 * File:     utility.c
 * Target:   PIC16F877A
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.65
 *
 */
#include "utility.h"
/*
 * Convert a 16-bit unsigned value to an ASCII string of decimal digits
 */
void BinToDecASCII(char * buf, unsigned short val)
{
    char c;

    if(buf)
    {
        c  = 0;
        if( val >= 40000)
        {
            c |= '4';
            val -= 40000;
        }
        if( val >= 20000)
        {
            c |= '2';
            val -= 20000;
        }
        if( val >= 10000)
        {
            c |= '1';
            val -= 10000;
        }
        if(c)
        {
            *buf++ = c;
            c &= '0';
        }

        if( val >= 8000)
        {
            c |= '8';
            val -= 8000;
        }
        if( val >= 4000)
        {
            c |= '4';
            val -= 4000;
        }
        if( val >= 2000)
        {
            c |= '2';
            val -= 2000;
        }
        if( val >= 1000)
        {
            c |= '1';
            val -= 1000;
        }
        if(c)
        {
            *buf++ = c;
            c &= '0';
        }

        if( val >= 800)
        {
            c |= '8';
            val -= 800;
        }
        if( val >= 400)
        {
            c |= '4';
            val -= 400;
        }
        if( val >= 200)
        {
            c |= '2';
            val -= 200;
        }
        if( val >= 100)
        {
            c |= '1';
            val -= 100;
        }
        if(c)
        {
            *buf++ = c;
            c &= '0';
        }

        if( val >= 80)
        {
            c |= '8';
            val -= 80;
        }
        if( val >= 40)
        {
            c |= '4';
            val -= 40;
        }
        if( val >= 20)
        {
            c |= '2';
            val -= 20;
        }
        if( val >= 10)
        {
            c |= '1';
            val -= 10;
        }
        if(c)
        {
            *buf++ = c;
            c &= '0';
        }
        *buf++ = val + '0';
        *buf = 0;
    }
}
