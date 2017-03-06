    list    p=10F200
    list    n=0, c=250      ; No page breaks, support long lines in list file
    list    r=dec
    #include "P10F200.INC"
    
    __CONFIG   _MCLRE_OFF & _CP_OFF & _WDT_OFF
    org 0x000
    goto    main
;
; PIC10F200 Serial TX output
;
; Baud rate is FOSC/(clocks per instruction cycle)/(instruction cycles per bit)
; or FOSC/4/8 with a 4MHz oscillator the baud rate is 125K bits per second.
;
; Warnings: 
;   The PIC10F200 4MHz oscillator accuracy is at best 1% so this will be unreliable.
;
;   This code uses Read-Modify-Write on a GPIO port register. This is know to have
;   problems when the GPIO output drives a low impedance load. You have been warned.
;
#define TX_out_bit_position (1)

    cblock  0x10
TX_byte
    endc


TX_out:
    movwf   TX_byte                     ; Save byte to be sent
    bcf     GPIO,TX_out_bit_position    ; assert start bit
    rrf     TX_byte,W                   ; transform data bits
    xorwf   TX_byte,F                   ; to an NRZ pattern
    BSF     TX_byte,7
    movlw   (1<<TX_out_bit_position)    ; WREG = bit position mask of TX output bit
    NOP
TX_out_loop:
    btfsc   STATUS,C
    xorwf   GPIO,F                      ; assert bit 
    clrc
    rrf     TX_byte,F
    movf    TX_byte,F
    bnz     TX_out_loop
    GOTO    $+1
    NOP
    bsf     GPIO,TX_out_bit_position    ; assert stop bit
    NOP
    NOP
    retlw   0
;
; Return character of ROM string
; Input:    WREG = Pointer to begining of string to be sent.
;           StringOutIdx = offsct from start of string.
;
; Output:   WREG = Character of string at StringOutIdx
;           StringOutIdx = StringOutIdx + 1
;
    cblock
StringOutIdx
    endc

GetNextCharacter:
    addwf   StringOutIdx,W
    incf    StringOutIdx,F
    movwf   PCL
;
; Strings to send
;
aszHello dt "Hello World!",0x0D,0x0A,0x00
;
;
;

main:
    andlw   0xFE                        ; Turn off CLOCK OUT on GPIO.GP2
    movwf   OSCCAL
    movlw   b'11000111'                 ; TIMER0 clock is FOSC/4 with 1:256 prescaler
    option                              ;
    clrf    TMR0
;
; Wait about 500 milliseconds before setting the output bits after a POR.
; This prevents problems with the In-Circuit-Serial-Programming.
;
    movlw   d'16'
    movwf   TX_byte
POR_WaitLoop:
    btfss   TMR0,7
    goto    POR_WaitLoop
    bcf     TMR0,7
    decfsz  TX_byte,F
    goto    POR_WaitLoop

    movlw   0xFF^(1<<TX_out_bit_position)
    tris    GPIO                        ; GP1 is the TX output bit
    bsf     GPIO,TX_out_bit_position    ; assert stop bit
;
; Wait for stop bit to be asserted for at least 10 bit times.
;
TX_InitWaitLoop:
    btfss   TMR0,7
    goto    TX_InitWaitLoop
;
; Send boot message
;
    clrf    StringOutIdx    ; Set String output index to first character
    goto    BootMessage
BootMessageLoop:
    call    TX_out
BootMessage:
    movlw   aszHello        ; Pointer to string we are sending
    call    GetNextCharacter
    iorlw   0
    bnz     BootMessageLoop
hang:
    goto    hang

    END
