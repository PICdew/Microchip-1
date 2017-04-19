
;**********************************************************
; projserial.asm
;
;
; This program is a feedback controller of a DC FAN
; PIC16F877, 8MHz Oscillator, 12VDC 4 Wire Fan, LCD Display
;**********************************************************

;
;                         PIC16F877
;                 +----------:_:----------+
;   S1  VPP ->  1 : MCLR/VPP      PGD/RB7 : 40 <> PGD
;           <>  2 : RA0/AN0       PGC/RB6 : 39 <> PGC
; 0-5V Tach ->  3 : RA1               RB5 : 38 <>
;           <>  4 : RA2               RB4 : 37 <>
;           <>  5 : RA3           PGM/RB3 : 36 <>
;   S2      ->  6 : RA4               RB2 : 35 <>
;           <>  7 : RA5               RB1 : 34 <>
;           <>  8 : RE0               RB0 : 33 <>
;           <>  9 : RE1               VDD : 32 <- PWR
;           <> 10 : RE2               VSS : 31 <- GND
;       PWR -> 11 : VDD               RD7 : 30 -> LCD_E
;       GND -> 12 : VSS               RD6 : 29 -> LCD_RW
; 8MHz OSC  -> 13 : OSC1              RD5 : 28 <>
;           <> 14 : OSC2              RD4 : 27 -> LCD_RS
;           <> 15 : RC0/T1CKI   RX/DT/RC7 : 26 <- RXD
;PWM FAN    <- 16 : RC1/CCP2    TX/CK/RC6 : 25 -> TXD
;           <> 17 : RC2/CCP1          RC5 : 24 <>
;       SCL <> 18 : RC3/SCL       SDA/RC4 : 23 <>
;    LCD_D4 <> 19 : RD0               RD3 : 22 <> LCD_D7
;    LCD_D5 <> 20 : RD1               RD2 : 21 <> LCD_D6
;                 +-----------------------:
;                          DIP-40
;





	list	p=16f877
	include "p16f877.inc"

config_1	EQU	_CP_OFF & _CPD_OFF & _LVP_OFF & _WDT_OFF

config_2	EQU	_BODEN_OFF & _PWRTE_OFF & _XT_OSC

	__CONFIG	config_1 & config_2


;********************************************************************
; Macro definitions
;********************************************************************

; Save W and STATUS contents during interrupts

push macro

	movwf	WTemp			; Save W in WTemp in common memory

	swapf	STATUS,W		; Swap the STATUS nibbles and save in W

	movwf	StatusTemp		; Save STATUS in StatusTemp in common
					; memory.
	endm

pop	macro

	swapf	StatusTemp,W		; Swap StatusTemp register into W

	movwf	STATUS			; Copy W into STATUS
					; (Sets bank to original state)

	swapf	WTemp,F			; Swap W into WTemp

	swapf	WTemp,W			; Unswap WTemp into W

	endm

;********************************************************************
; Begin executable code
;********************************************************************

;===============================================================

	cblock	0x20
		D1			;For Delay
		D2			;For Delay
		D3			;For Delay
		X1			;For Counter
		REFERENCE		;For Reference Speed
		CHANGE			;For error correction

		count			;used in looping routines
		count1			;used in delay routine
		counta			;used in delay routine
		countb			;used in delay routine

		tmp1			;temporary storage
		tmp2
		templcd			;temp store for 4 bit mode
		templcd2
		NumL			;Binary inputs for decimal convert routine
		NumH

		TenK			;Decimal outputs from convert routine
		Thou
		Hund
		Tens
		Ones
	endc

	cblock	0x71			; Common memory assignments.
		WTemp			; This cblock assigns the data memory
		StatusTemp		; address 0x71 to the variable WTemp and
	endc				; 0x72 to StatusTemp. Addresses 0x70 through
					; 0x7F are common or shared memory addresses.
					; This means that if you read or write to
					; memory location 0x70, you automatically
					; read or  write to 0xF0, 0x170 and 0x1F0.
					; However, these four addresses are
					; reserved when using the debugger, so it
					; is best to start with 0x71.

;-----------------------------------------------------------------------------------------------------------
LCD_PORT	equ	PORTD
LCD_TRIS	equ	TRISD
LCD_RS		equ	0x04	;LCD handshake lines
LCD_RW		equ	0x06
LCD_E		equ	0x07
Same    	equ 1
mulcnd  	equ 09      ; 8 bit multiplicand
mulplr  	equ 10      ; 8 bit multiplier
H_byte  	equ 12      ; High byte of the 16 bit result
L_byte  	equ 13      ; Low byte of the 16 bit result
count2  	equ 14      ; loop counter


;********************************************************************
; Begin executable code
;********************************************************************

	org 0x0000 ; Reset Vector
	nop
	goto	Main


;********************************************************************
; Interrupt vector
;********************************************************************

	org 0x0004
	goto	ISR ;Interrupt Service Routine

;------------------------------------------------------------------------------------------------------------
HEX_Table
		addwf	PCL,F
		retlw	0x30
		retlw	0x31
		retlw	0x32
		retlw	0x33
		retlw	0x34
		retlw	0x35
		retlw	0x36


Text
		addwf	PCL,F
		retlw	'F'
		retlw	'A'
		retlw	'N'
		retlw	' '
		retlw	'R'
		retlw	'P'
		retlw	'M'
		retlw	0x00


;====================================== MAIN PROGRAM ===================================
Main
	call	Init ; Intialization
;	banksel	PIR1
;	btfss	PIR1, TMR1IF
;	call	Message
;	goto	SpeedLoop
;------------------------------- TACHOMETER INPUT INTO PORTA,1 -----------------------------------------
SpeedLoop
	btfss	PORTA,1
	goto	$-1
	call	Increment
	btfsc	PORTA,1
	goto	$-1
	btfss	PIR1,TMR1IF

	goto	SpeedLoop

Increment
	btfsc	PORTA,1
	incf	X1,F ; increment counter at every pulse
	return

;------------------------------- Initilization of System -----------------------------------------
Init
	banksel	PORTA
	clrf	PORTA
	clrf	PORTB
	clrf	PORTC
	clrf	PORTD
	clrf	X1
	clrf	REFERENCE

;Port Init

	banksel	ADCON1				;PortA as digital input
	movlw	b'00000110'
	movwf	ADCON1

	movlw	b'11111111'			;Set PORTA as Inputs
	banksel	TRISA
	movwf	TRISA

	movlw	b'00000000'			;Set PORTB as Outputs
	banksel	TRISB
	movwf	TRISB

;PWM Setup

	movlw	d'91'				;PWM Setup: Period KHZ(19.152KHZ)
	banksel	PR2
	movwf	PR2

	banksel	TRISC				; Port C set as Outputs for PWM Output.  CCPR2 is connected to the PWM pin of the DC Fan
	bcf	TRISC,1
	bcf	TRISC,2

	banksel	TMR2
	clrf	TMR2
	movlw	0X00				;Initial Duty Cycle is 0%
	banksel	CCPR2L
	movwf	CCPR2L

	movlw	b'00000100'			;Turn on Timer2, Prescale =1
	banksel	T2CON
	movwf	T2CON


	movlw	b'00001100'			; CCP2 is set to PWM Mode
	banksel	CCP2CON
	movwf	CCP2CON

; Timer 1 Setup

	movlw	0X00
	banksel	TMR1H
	movwf	TMR1H				;Timer= 0000-FFFFH = 65535*8/(8M/4) = 0.26214s Prescale = 8
	movlw	0X00
	banksel	TMR1L
	movwf	TMR1L

	movlw	b'00110001'			;Pre=1:8 TMR1=Int TMR1=ON ; 00000001
	banksel	T1CON
	movwf	T1CON


	movlw	b'00000001' ;TMR1IE=1
	banksel	PIE1
	movwf	PIE1

	movlw	b'11000000' ;GIE=1, PEIE=1
	banksel	INTCON
	movwf	INTCON

; Serial Setup and Initilization

SERIAL_SETUP:
	movlw	d'51'				; BRGH = 1 and 8MHZ Oscillator for 9600 Baud Rate
	banksel	SPBRG
	movwf	SPBRG

	movlw	b'00100100'
	banksel	TXSTA
	movwf	TXSTA				;Enable transmission & high baud rate


	movlw	b'10010000'
	banksel	RCSTA
	movwf	RCSTA				;Enable serial port & continuous reception

; Clear Ports and Counts
	clrf	count
	clrf	PORTA
	clrf	PORTB
	clrf	PORTC
	clrf	PORTD
	clrf	NumL
	clrf	NumH

SetPorts
	banksel	TRISD	;select bank 1
	movlw	b'00000000'			;make all pins outputs
	movwf	LCD_TRIS
	movwf	TRISD

	banksel	LCD_Init

	call	LCD_Init			;setup LCD
	clrf	count				;set counter register to zero



	return

;######################## END OF INITIALIZATION##########################
;^^^^^^^^^^^^^^^^^^^^^^^^ SUBROUTINE^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;-----------Get data for reference speed -------------------
Receive
	movf	RCREG,W				;Get received data to W
	banksel	REFERENCE
	movwf	REFERENCE

	return

;*********************** INTERRUPT SERVICE ROUTINE******************************
ISR


	push

SerialReference
	btfsc	PIR1,RCIF
	call	Receive
	goto	GETDATA

GETDATA

	banksel	PIR1
	bcf	PIR1,TMR1IF
	banksel	X1
	movf	X1,W				; Get value of counter,detect speed
	banksel	REFERENCE
	subwf	REFERENCE,W			; Ref speed - Detect speed
	movwf	CHANGE				; CHANGE = error correction
	btfsc	STATUS,C			; Reference < Detect ?
	goto	GREATER				; No. Jump to > or = check

LESS
	movf	CHANGE,W
	addwf	CCPR2L,F			; Add duty cycle with error correction
	goto	SHOWSPEED

GREATER
	btfsc	STATUS,Z			; Reference = Detect?
	goto	SHOWSPEED			; Yes, no need correction.
	movf	CHANGE,W			; Detect speed > ref speed, decrease duty cycle with error correction
	sublw	0XFF				; Convert the negative value to positive value
	subwf	CCPR2L,F

SHOWSPEED
	clrf	X1				;Reset Counter
	movf	REFERENCE,W
	sublw	0X00
	btfss	STATUS,Z			; Reference speed = 0?
	goto	CONTINUE			; No, continue the process

STOPMOTOR
	movlw	0X00 ; Yes. Stop motor
	movwf	CCPR2L

CONTINUE
	retfie

	pop




;******************** END OF INTERRUPT PROCESS*************************

;Subroutines and text tables

;LCD routines

;Initialise LCD
LCD_Init	call	LCD_Busy		;wait for LCD to settle

		movlw	0x20			;Set 4 bit mode
		call	LCD_Cmd

		movlw	0x28			;Set display shift
		call	LCD_Cmd

		movlw	0x06			;Set display character mode
		call	LCD_Cmd

		movlw	0x0c			;Set display on/off and cursor command
		call	LCD_Cmd			;Set cursor off

		call	LCD_Clr			;clear display

		retlw	0x00

; command set routine
LCD_Cmd
		movwf	templcd
		swapf	templcd,W		;send upper nibble
		andlw	0x0f			;clear upper 4 bits of W
		movwf	LCD_PORT
		bcf	LCD_PORT,LCD_RS		;RS line to 1
		call	Pulse_e			;Pulse the E line high

		movf	templcd,W		;send lower nibble
		andlw	0x0f			;clear upper 4 bits of W
		movwf	LCD_PORT
		bcf	LCD_PORT,LCD_RS		;RS line to 1
		call	Pulse_e			;Pulse the E line high
		call		LCD_Busy
		return


LCD_CharD
		addlw	0x30			;add 0x30 to convert to ASCII
LCD_Char
		movwf	templcd
		swapf	templcd,W		;send upper nibble
		andlw	0x0f			;clear upper 4 bits of W
		movwf	LCD_PORT
		bsf	LCD_PORT,LCD_RS		;RS line to 1
		call	Pulse_e			;Pulse the E line high

		movf	templcd,W		;send lower nibble
		andlw	0x0f			;clear upper 4 bits of W
		movwf	LCD_PORT
		bsf	LCD_PORT,LCD_RS		;RS line to 1
		call	Pulse_e			;Pulse the E line high
		call		LCD_Busy
		retlw	0x00

LCD_Line1
		movlw	0x80			;move to 1st row, first column
		call	LCD_Cmd
		retlw	0x00

LCD_Line2
		movlw	0xc0			;move to 2nd row, first column
		call	LCD_Cmd
		retlw	0x00

LCD_Line1W
		addlw	0x80			;move to 1st row, column W
		call	LCD_Cmd
		retlw	0x00

LCD_Line2W	addlw	0xc0			;move to 2nd row, column W
		call	LCD_Cmd
		retlw	0x00

LCD_CurOn	movlw	0x0d			;Set display on/off and cursor command
		call	LCD_Cmd
		retlw	0x00

LCD_CurOff	movlw	0x0c			;Set display on/off and cursor command
		call	LCD_Cmd
		retlw	0x00

LCD_Clr		movlw	0x01			;Clear display
		call	LCD_Cmd
		retlw	0x00

LCD_HEX		movwf	tmp1
		swapf	tmp1,W
		andlw	0x0f
		call	HEX_Table
		call	LCD_Char
		movf	tmp1,W
		andlw	0x0f
		call	HEX_Table
		call	LCD_Char
		retlw	0x00

Delay255	movlw	0xFF			;delay 255 mS
		goto	d4
Delay100	movlw	d'100'			;delay 100mS
		goto	d4
Delay50		movlw	d'50'			;delay 50mS
		goto	d4
Delay20		movlw	d'20'			;delay 20mS
		goto	d4
Delay5		movlw	0x05			;delay 5.000 ms (8 MHz clock)
		banksel	count1
d4		movwf	count1
d5		movlw	0x8F			;delay 1mS
		movwf	counta
		movlw	0x02
		movwf	countb
Delay_0
		decfsz	counta,F
		goto	$+2
		decfsz	countb,F
		goto	Delay_0

		decfsz	count1	,F
		goto	d5
		return

Pulse_e		bsf	LCD_PORT,LCD_E
		nop
		bcf	LCD_PORT,LCD_E
		return

LCD_Busy
		bsf	STATUS,RP0		;set bank 1
		movlw	0x0f			;set Port for input
		movwf	LCD_TRIS
		bcf	STATUS,RP0		;set bank 0
		bcf	LCD_PORT,LCD_RS		;set LCD for command mode
		bsf	LCD_PORT,LCD_RW		;setup to read busy flag
		bsf	LCD_PORT,LCD_E
		swapf	LCD_PORT,W		;read upper nibble (busy flag)
		bcf	LCD_PORT,LCD_E
		movwf	templcd2
		bsf	LCD_PORT,LCD_E		;dummy read of lower nibble
		bcf	LCD_PORT,LCD_E
		btfsc	templcd2,7		;check busy flag, high = busy
		goto	LCD_Busy		;if busy check again
		bcf	LCD_PORT,LCD_RW
		bsf	STATUS,RP0		;set bank 1
		movlw	0x00			;set Port for output
		movwf	LCD_TRIS
		bcf	STATUS,RP0		;set bank 0
		return

;end of LCD routines



;This routine downloaded from http://www.piclist.com
Convert:					; Takes number in NumH:NumL
						; Returns decimal in
						; TenK:Thou:Hund:Tens:Ones

		swapf   NumH,W
		iorlw	B'11110000'
		movwf	Thou
		addwf	Thou,F
		addlw   0XE2
		movwf	Hund
		addlw   0X32
		movwf	Ones

		movf	NumH,W
		andlw   0X0F
		addwf	Hund,F
		addwf	Hund,F
		addwf	Ones,F
		addlw   0XE9
		movwf	Tens
		addwf	Tens,F
		addwf	Tens,F

		swapf   NumL,W
		andlw   0X0F
		addwf	Tens,F
		addwf	Ones,F

		rlf	Tens,F
		rlf	Ones,F
		comf	Ones,F
		rlf	Ones,F

		movf	NumL,W
		andlw   0X0F
		addwf	Ones,F
		rlf	Thou,F

		movlw	0X07
		movwf	TenK

					; At this point, the original number is
					; equal to
					; TenK*10000+Thou*1000+Hund*100+Tens*10+Ones
					; if those entities are regarded as two's
					; complement binary.  To be precise, all of
					; them are negative except TenK.  Now the number
					; needs to be normalized, but this can all be
					; done with simple byte arithmetic.

		movlw	0X0A		; Ten
Lb1:
		addwf	Ones,F
		decf    Tens,F
		btfss	3,0
		goto	Lb1
Lb2:
		addwf	Tens,F
		decf    Hund,F
		btfss	3,0
		goto	Lb2
Lb3:
		addwf	Hund,F
		decf    Thou,F
		btfss	3,0
		goto	Lb3
Lb4:
		addwf	Thou,F
		decf    TenK,F
		btfss	3,0
		goto	Lb4

		retlw	0x00

; *****************************         Begin Multiplier Routine
;mpy_S	clrf	H_byte
;	clrf	L_byte
;	movlw	8
;	movwf	count2
;	movf	mulcnd,W
;	bcf	STATUS,C			; Clear the carry bit in the status Reg.
;loop	rrf	mulplr,F
;	btfsc	STATUS,C
;	addwf	H_byte,Same
;	rrf	H_byte,Same
;	rrf	L_byte,Same
;	decfsz  count2,F
;	goto	loop
;
;	retlw	0


Message

		movf	count,W			;put counter value in W
		call	Text			;get a character from the text table
		xorlw	0x00			;is it a zero?
		btfsc	STATUS,Z
		call	NextMessage
		call	LCD_Char
		incf	count,F
		goto	Message

NextMessage
		movlw	d'2'
		call	LCD_Line2W		;move to 2nd row, third column
		call	Convert			;convert to decimal
		movf	TenK,W			;display decimal characters
		call	LCD_CharD		;using LCD_CharD to convert to ASCII
		movf	Thou,W
		call	LCD_CharD
		movf	Hund,W
		call	LCD_CharD
		movf	Tens,W
		call	LCD_CharD
		movf	Ones,W
		call	LCD_CharD
		movlw	' ' 			;display a 'space'
		call	LCD_Char
		movf	NumH,W			;and counter in hexadecimal
		call	LCD_HEX
		movf	NumL,W
		call	LCD_HEX
		incfsz	NumL,F
		goto	Next
		incf	NumH,F
Next
		call	Delay20			;wait so you can see the digits change

		goto	NextMessage
		return


		END
;-------------------------------------END OF PROGRAM------------------------------------------------