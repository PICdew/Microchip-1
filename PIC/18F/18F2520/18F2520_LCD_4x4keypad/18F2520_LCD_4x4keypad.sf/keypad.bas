//
// File:   keypad.c
// Author:
//
// Target: PIC18F24K20, PIC18F2520
//
module keypad

include "init_h.bas"
include "bitdefs.bas"

public dim
    KP_ROW1_IN  as PORTB.bits(0),
    KP_ROW2_IN  as PORTB.bits(1),
    KP_ROW3_IN  as PORTB.bits(2),
    KP_ROW4_IN  as PORTB.bits(3),
    KP_COL1_OUT as LATB.bits(4),
    KP_COL2_OUT as LATB.bits(5),
    KP_COL3_OUT as LATC.bits(2),
    KP_COL4_OUT as LATC.bits(3) 

public dim
    KP_ROW1_IN_DIR  as TRISB.bits(0),
    KP_ROW2_IN_DIR  as TRISB.bits(1),
    KP_ROW3_IN_DIR  as TRISB.bits(2),
    KP_ROW4_IN_DIR  as TRISB.bits(3),
    KP_COL1_OUT_DIR as TRISB.bits(4),
    KP_COL2_OUT_DIR as TRISB.bits(5),
    KP_COL3_OUT_DIR as TRISC.bits(2),
    KP_COL4_OUT_DIR as TRISC.bits(3)

// enum eKeyEvent
public const
    eNoEvent = 0,
    eKeyChanged = 1

public type eKeyEvent_t = byte

public structure KeypadEvent_t
    ButtonMatrix    as word
    ChangedMask     as word
end structure


dim
    KP_Sample   as word,
    KP_Last     as word,
    KP_Changed  as word,
    KP_Stable   as word,
    KP_DebounceCounter  as byte

//
// Initialize the GPIO pins used for the 3x4 keypad
//
public sub Keypad_Init()
    KP_ROW1_IN_DIR  = 1
    KP_ROW2_IN_DIR  = 1
    KP_ROW3_IN_DIR  = 1
    KP_ROW4_IN_DIR  = 1
    KP_COL1_OUT_DIR = 0
    KP_COL2_OUT_DIR = 0
    KP_COL3_OUT_DIR = 0
    KP_COL4_OUT_DIR = 0
    KP_Last = 0
    KP_DebounceCounter = 0
end sub

//
// Called from application loop to sample all keys
// in the keypad matrix, debounce and update the
// stable state.
//
// This function should be called every 1 to 2 milliseconds.
// When called too often the buttons do not debounce correctly.
// When called too infrequently the buttons seem unresponsive.
//
public sub Keypad_Scan()
    KP_Sample = 0
    KP_COL1_OUT = 1
    KP_COL2_OUT = 1
    KP_COL3_OUT = 1
    KP_COL4_OUT = 1
    KP_COL2_OUT_DIR = 1
    KP_COL3_OUT_DIR = 1
    KP_COL4_OUT_DIR = 1
    KP_COL1_OUT_DIR = 0

    KP_COL1_OUT = 0
    if (KP_ROW1_IN = 0) then
        KP_Sample.bits(0) = 1
    endif
    if (KP_ROW2_IN = 0) then
        KP_Sample.bits(1) = 1
    endif
    if (KP_ROW3_IN = 0) then
        KP_Sample.bits(2) = 1
    endif
    if (KP_ROW4_IN = 0) then
        KP_Sample.bits(3) = 1
    endif

    KP_COL1_OUT = 1
    KP_COL1_OUT_DIR = 1
    KP_COL2_OUT_DIR = 0
    KP_COL2_OUT = 0
    if (KP_ROW1_IN = 0) then
        KP_Sample.bits(4) = 1
    endif
    if (KP_ROW2_IN = 0) then
        KP_Sample.bits(5) = 1
    endif
    if (KP_ROW3_IN = 0) then
        KP_Sample.bits(6) = 1
    endif
    if (KP_ROW4_IN = 0) then
        KP_Sample.bits(7) = 1
    endif

    KP_COL2_OUT = 1
    KP_COL2_OUT_DIR = 1
    KP_COL3_OUT_DIR = 0
    KP_COL3_OUT = 0
    if (KP_ROW1_IN = 0) then
        KP_Sample.bits(8) = 1
    endif
    if (KP_ROW2_IN = 0) then
        KP_Sample.bits(9) = 1
    endif
    if (KP_ROW3_IN = 0) then
        KP_Sample.bits(10) = 1
    endif
    if (KP_ROW4_IN = 0) then
        KP_Sample.bits(11) = 1
    endif

    KP_COL3_OUT_DIR = 1
    KP_COL3_OUT = 1
    KP_COL4_OUT_DIR = 0
    KP_COL4_OUT = 0
    if (KP_ROW1_IN = 0) then
        KP_Sample.bits(12) = 1
    endif
    if (KP_ROW2_IN = 0) then
        KP_Sample.bits(13) = 1
    endif
    if (KP_ROW3_IN = 0) then
        KP_Sample.bits(14) = 1
    endif
    if (KP_ROW4_IN = 0) then
        KP_Sample.bits(15) = 1
    endif

    KP_COL3_OUT = 0
    KP_COL2_OUT = 0
    KP_COL1_OUT = 0
    KP_COL1_OUT_DIR = 0
    KP_COL2_OUT_DIR = 0
    KP_COL3_OUT_DIR = 0
    KP_COL4_OUT_DIR = 0

    // check if matrix changed since last scan
    if ((KP_Sample xor KP_Last) <> 0) then
        KP_Last = KP_Sample
        KP_DebounceCounter = 0
        exit
    endif

    // check if we have sampled inputs for long enough to debounce
    if (KP_DebounceCounter < KP_DEBOUNCE_COUNT) then
        inc(KP_DebounceCounter)
        exit
    endif

    // Update the stable output only after pevious stable state has been read
    if (KP_Changed = 0) then
        KP_Changed = KP_Sample xor KP_Stable
        KP_Stable = KP_Sample
    endif
end sub

//
// Returns non-zero when a key event occurs.
// A key event is when one key is pressed or released.
//
public function Keypad_GetEvent() as eKeyEvent_t
    if (KP_Changed = 0) then
        result = eNoEvent
    else
        result = eKeyChanged
    endif
end function

//
// Returns ASCII character of keypad event.
// If more than one key is pressed returns ZERO.
//
'public function Keypad_GetKey(byref pKeypadEvent as KeypadEvent_t) as byte
public function Keypad_GetKey() as byte
    dim
        Key as byte,
        ButtonMatrix as word,
        ChangedMask as word

    Key = 0
    INTCON.bits(TMR0IE) = 0  // disable tick to read keypad sample memory
    ButtonMatrix = KP_Stable
    ChangedMask  = KP_Changed
    // Tell ISR we have read the current state
    KP_Changed = 0
    INTCON.bits(TMR0IE) = 1  // enable tick

    // When pointer not NULL return current state of the keypad matrix
    {
    pKeypadEvent.ButtonMatrix = ButtonMatrix
    pKeypadEvent.ChangedMask  = ChangedMask
    }
    
    // decode key in ASCII
    if (ChangedMask <> 0) then
        select (ButtonMatrix)
            case $0001
                Key = "1"
            case $0002
                Key = "4"
            case $0004
                Key = "7"
            case $0008
                Key = "E"
            case $0010
                Key = "2"
            case $0020
                Key = "5"
            case $0040
                Key = "8"
            case $0080
                Key = "0"
            case $0100
                Key = "3"
            case $0200
                Key = "6"
            case $0400
                Key = "9"
            case $0800
                Key = "."
            case $1000
                Key = "R"
            case $2000
                Key = "L"
            case $4000
                Key = "U"
            case $8000
                Key = "D"
            else    // default:
                Key = 0
        end select
    endif

    result = Key
end function

// init
KP_Sample = 0
KP_Last = 0
KP_Changed = 0
KP_Stable = 0
KP_DebounceCounter = 0

end module
