//
// File:   keypad.c
// Author:
//
// Target: PIC18F24K20, PIC18F2520
//
Module keypad

Include "init_h.bas"
Include "bitdefs.bas"

Public Dim
    KP_ROW1_IN  As PORTB.bits(0),
    KP_ROW2_IN  As PORTB.bits(1),
    KP_ROW3_IN  As PORTB.bits(2),
    KP_ROW4_IN  As PORTB.bits(3),
    KP_COL1_OUT As LATB.bits(4),
    KP_COL2_OUT As LATB.bits(5),
    KP_COL3_OUT As LATC.bits(2),
    KP_COL4_OUT As LATC.bits(3) 

Public Dim
    KP_ROW1_IN_DIR  As TRISB.bits(0),
    KP_ROW2_IN_DIR  As TRISB.bits(1),
    KP_ROW3_IN_DIR  As TRISB.bits(2),
    KP_ROW4_IN_DIR  As TRISB.bits(3),
    KP_COL1_OUT_DIR As TRISB.bits(4),
    KP_COL2_OUT_DIR As TRISB.bits(5),
    KP_COL3_OUT_DIR As TRISC.bits(2),
    KP_COL4_OUT_DIR As TRISC.bits(3)

// enum eKeyEvent
Public Const
    eNoEvent = 0,
    eKeyChanged = 1

Public Type eKeyEvent_t = Byte

Public Structure KeypadEvent_t
    ButtonMatrix    As Word
    ChangedMask     As Word
End Structure


Dim
    KP_Sample   As Word,
    KP_Last     As Word,
    KP_Changed  As Word,
    KP_Stable   As Word,
    KP_DebounceCounter  As Byte

//
// Initialize the GPIO pins used for the 3x4 keypad
//
Public Sub Keypad_Init()
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
End Sub

//
// Called from application loop to sample all keys
// in the keypad matrix, debounce and update the
// stable state.
//
// This function should be called every 1 to 2 milliseconds.
// When called too often the buttons do not debounce correctly.
// When called too infrequently the buttons seem unresponsive.
//
Public Sub Keypad_Scan()
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
    If (KP_ROW1_IN = 0) Then
        KP_Sample.bits(0) = 1
    EndIf
    If (KP_ROW2_IN = 0) Then
        KP_Sample.bits(1) = 1
    EndIf
    If (KP_ROW3_IN = 0) Then
        KP_Sample.bits(2) = 1
    EndIf
    If (KP_ROW4_IN = 0) Then
        KP_Sample.bits(3) = 1
    EndIf

    KP_COL1_OUT = 1
    KP_COL1_OUT_DIR = 1
    KP_COL2_OUT_DIR = 0
    KP_COL2_OUT = 0
    If (KP_ROW1_IN = 0) Then
        KP_Sample.bits(4) = 1
    EndIf
    If (KP_ROW2_IN = 0) Then
        KP_Sample.bits(5) = 1
    EndIf
    If (KP_ROW3_IN = 0) Then
        KP_Sample.bits(6) = 1
    EndIf
    If (KP_ROW4_IN = 0) Then
        KP_Sample.bits(7) = 1
    EndIf

    KP_COL2_OUT = 1
    KP_COL2_OUT_DIR = 1
    KP_COL3_OUT_DIR = 0
    KP_COL3_OUT = 0
    If (KP_ROW1_IN = 0) Then
        KP_Sample.bits(8) = 1
    EndIf
    If (KP_ROW2_IN = 0) Then
        KP_Sample.bits(9) = 1
    EndIf
    If (KP_ROW3_IN = 0) Then
        KP_Sample.bits(10) = 1
    EndIf
    If (KP_ROW4_IN = 0) Then
        KP_Sample.bits(11) = 1
    EndIf

    KP_COL3_OUT_DIR = 1
    KP_COL3_OUT = 1
    KP_COL4_OUT_DIR = 0
    KP_COL4_OUT = 0
    If (KP_ROW1_IN = 0) Then
        KP_Sample.bits(12) = 1
    EndIf
    If (KP_ROW2_IN = 0) Then
        KP_Sample.bits(13) = 1
    EndIf
    If (KP_ROW3_IN = 0) Then
        KP_Sample.bits(14) = 1
    EndIf
    If (KP_ROW4_IN = 0) Then
        KP_Sample.bits(15) = 1
    EndIf

    KP_COL4_OUT = 1
    KP_COL3_OUT = 1
    KP_COL2_OUT = 1
    KP_COL1_OUT = 1
    KP_COL1_OUT_DIR = 1
    KP_COL2_OUT_DIR = 1
    KP_COL3_OUT_DIR = 1
    KP_COL4_OUT_DIR = 1

    // check if matrix changed since last scan
    If ((KP_Sample Xor KP_Last) <> 0) Then
        KP_Last = KP_Sample
        KP_DebounceCounter = 0
        Exit
    EndIf

    // check if we have sampled inputs for long enough to debounce
    If (KP_DebounceCounter < KP_DEBOUNCE_COUNT) Then
        Inc(KP_DebounceCounter)
        Exit
    EndIf

    // Update the stable output only after pevious stable state has been read
    If (KP_Changed = 0) Then
        KP_Changed = KP_Sample Xor KP_Stable
        KP_Stable = KP_Sample
    EndIf
End Sub

//
// Returns non-zero when a key event occurs.
// A key event is when one key is pressed or released.
//
Public Function Keypad_GetEvent() As eKeyEvent_t
    If (KP_Changed = 0) Then
        result = eNoEvent
    Else
        result = eKeyChanged
    EndIf
End Function

//
// Returns ASCII character of keypad event.
// If more than one key is pressed returns ZERO.
//
'public function Keypad_GetKey(byref pKeypadEvent as KeypadEvent_t) as byte
Public Function Keypad_GetKey() As Byte
    Dim
        Key As Byte,
        ButtonMatrix As Word,
        ChangedMask As Word

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
    If (ChangedMask <> 0) Then
        Select (ButtonMatrix)
            Case $0001
                Key = "1"
            Case $0002
                Key = "4"
            Case $0004
                Key = "7"
            Case $0008
                Key = "E"
            Case $0010
                Key = "2"
            Case $0020
                Key = "5"
            Case $0040
                Key = "8"
            Case $0080
                Key = "0"
            Case $0100
                Key = "3"
            Case $0200
                Key = "6"
            Case $0400
                Key = "9"
            Case $0800
                Key = "."
            Case $1000
                Key = "R"
            Case $2000
                Key = "L"
            Case $4000
                Key = "U"
            Case $8000
                Key = "D"
            Else    // default:
                Key = 0
        End Select
    EndIf

    result = Key
End Function

// init
KP_Sample = 0
KP_Last = 0
KP_Changed = 0
KP_Stable = 0
KP_DebounceCounter = 0

End Module
