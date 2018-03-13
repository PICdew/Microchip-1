module bit_definitions

// INTCON
public const
    RBIF = 0,
    INT0IF = 1,
    TMR0IF = 2,
    RBIE = 3,
    INT0IE = 4,
    TMR0IE = 5,
    PEIE_GIEL = 6,
    GIE_GIEH = 7

public const
    GIEL = 6,
    GIEH = 7

// INTCON2
public const
    RBIP = 0,
    TMR0IP = 2,
    INTEDG2 = 4,
    INTEDG1 = 5,
    INTEDG0 = 6,
    _RBPU = 7

public const
    nRBPU = _RBPU


end module
