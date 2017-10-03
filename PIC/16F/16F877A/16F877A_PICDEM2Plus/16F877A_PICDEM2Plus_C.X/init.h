/* 
 * File:     init.h
 * Target:   PIC16F877A
 * Compiler: XC8 v1.42
 * IDE:      MPLABX v3.65
 *
 */

#ifndef INIT_H
#define INIT_H

#ifdef __XC8
 #undef COMPILER_NOT_FOUND
 #define COMPILER_XC8
 #include <xc.h>
 #if defined(__16F877A__)
  #define TARGET_877A
 #elif defined(__16F887__)
  #define TARGET_887
 #else
   #error "Code does not build for selected target"
 #endif
#else
 #ifdef __PICC__
  #undef COMPILER_NOT_FOUND
  #define COMPILER_HTC
  #include <htc.h>
  #if defined(_16F877A)
   #define TARGET_877A
  #elif defined(_16F887)
   #define TARGET_887
  #else
   #error "Code does not build for selected target"
  #endif
 #endif
#endif
    
#ifdef COMPILER_NOT_FOUND
#error "Unknown compiler. Code builds with XC8, HTC or C18"
#endif


#define FSYS (18432000L)
#define FCYC (FSYS/4L)
#define _XTAL_FREQ FSYS

#define APP_MESSAGE "LCD Test "
#define MAJOR_REV (1)
#define MINOR_REV (1)

void PIC_Init( void );

#endif

