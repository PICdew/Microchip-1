//
// File:   main.c
// Author:
//
// Target: PIC18F24K20, PIC18F2520
//
// Description:
//
//  See:  https://www.electro-tech-online.com/threads/reading-a-4x4-switch-matrix.153166/
//
Device = 18F2520
Clock = 1  // Remember to update system clock values in the init_h.bas file

Include "init_h.bas"
Include "init.bas"
Include "keypad.bas"
Include "lcd.bas"
Include "tick.bas"
Include "bitdefs.bas"

Dim gScanKeypadFlag As Byte

//
// Interrupt handlers
//
Interrupt ISR_Handler()
    // Handle system tick
    If (INTCON.bits(TMR0IE) = 1) And (INTCON.bits(TMR0IF) = 1) Then
        INTCON.bits(TMR0IF) = 0
        If(gScanKeypadFlag = 0) Then
            gScanKeypadFlag = 1
        EndIf
    EndIf
End Interrupt

//
// Display application name and version
//
Sub ShowVersion()
    Dim buffer As String(17) 
    buffer = #8 + #9 + #10 + #11 + #12 + #13 + #14 + #15 // All 8 character generator symbols in a string

    LCD_SetDDRamAddr(LINE_ONE)
    LCD_WriteConstString(@("Test: LCD+Keypad"))
    // Show what is in the character generator RAM
    LCD_SetDDRamAddr(LINE_TWO)
    LCD_WriteString(buffer) // invoke string write to LCD to get Swordfish to include the function in the build
    LCD_WriteConstString(@(" 18MAR15"))
End Sub

//
// Application
//
Dim
    Key As Byte,
    KeyPressedMessageFlag As Byte

main:
    PIC_Init()
    LCD_Init()
    Keypad_Init()
    Tick_Init()

    gScanKeypadFlag   = 0
    Enable(ISR_Handler) 

    // Display the application name and version information
    ShowVersion()
    KeyPressedMessageFlag = 0

    While (true)
        // Scan the kepad matrix about every 2 milliseconds
        If(gScanKeypadFlag <> 0) Then
            gScanKeypadFlag = 0
            Keypad_Scan()
        EndIf
        // check for and process key presses
        If (Keypad_GetEvent() = eKeyChanged) Then
            If (KeyPressedMessageFlag = 0) Then
                KeyPressedMessageFlag = 1
                LCD_SetDDRamAddr(LINE_TWO)
                LCD_WriteConstString(@("Key Pressed:    "))
            Else
                LCD_SetDDRamAddr(LINE_TWO+13)
                LCD_WriteData(Byte(" "))
            EndIf
            Key = Keypad_GetKey()
            If (Key <> 0) Then
                LCD_SetDDRamAddr(LINE_TWO+13)
                LCD_WriteData(Key)
                Select (Char(Key))
                    Case "0"
                    Case "1"
                    Case "2"
                    Case "3"
                    Case "4"
                    Case "5"
                    Case "6"
                    Case "7"
                    Case "8"
                    Case "9"
                    Case "E"
                    Case "."
                    Case "U"
                    Case "D"
                    Case "L"
                    Case "R"
                    Else
                        Break
                End Select
            EndIf
        EndIf
    End While

End Program
