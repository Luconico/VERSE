# Final class for handling events with an actor and parameter
event_handler(actor: type, param : type) := class<final>():

    # Internal static parameter used for the event
    StaticParam<internal> : param

    # Internal tuple to handle actor performance, takes an actor and a parameter, returns void
    OnActorPerform<internal> : type {_(:actor, :param) : void}

    # Public method to handle internal actor events by invoking the OnActorPerform function with the actor and static parameter
    InternalActorEvent<public>(Actor : actor): void = OnActorPerform(Actor, StaticParam)

Textures := module:
    items<public> := module:
    resources<public> := module:

Utils<public> := module:

    FormatCurrency<public>(Amount:int)<computes>:string =
        # Handle regular numbers (under 1000)
        if (Amount < 1000):
            return "{Amount}"
        
        # Handle millions (1000000 or more)
        if (Amount >= 1000000, MillionsPart := Quotient[Amount, 1000000], DecimalPart := Quotient[Mod[Amount, 1000000], 10000]):
            if (DecimalPart > 0):
                return "{MillionsPart}.{DecimalPart}M"
            return "{MillionsPart}M"
        
        # Handle thousands (between 1000 and 999999)
        if (ThousandsPart := Quotient[Amount, 1000], DecimalPart := Quotient[Mod[Amount, 1000], 100]):
            if (DecimalPart > 0):
                return "{ThousandsPart}.{DecimalPart}k"
            return "{ThousandsPart}k"
    
        return "{Amount}"

    StringToLevelID<public>(LevelID:string):int =
        var Hash:int = 0
        for (Index -> Char : LevelID):
            # Usar el valor numérico ASCII del caracter
            CharValue := GetCharValue(Char)
            Position := Index + 1
            set Hash = Hash + (CharValue * Position * 17)
        return Abs(Hash)
    
    # Función auxiliar para convertir char a int
    GetCharValue(C:char):int =
        # Asignar valores numéricos a cada caracter
        if (C = 'a' or C = 'A'). return 1
        if (C = 'b' or C = 'B'). return 2
        if (C = 'c' or C = 'C'). return 3
        if (C = 'd' or C = 'D'). return 4
        if (C = 'e' or C = 'E'). return 5
        if (C = 'f' or C = 'F'). return 6
        if (C = 'g' or C = 'G'). return 7
        if (C = 'h' or C = 'H'). return 8
        if (C = 'i' or C = 'I'). return 9
        if (C = 'j' or C = 'J'). return 10
        if (C = 'k' or C = 'K'). return 11
        if (C = 'l' or C = 'L'). return 12
        if (C = 'm' or C = 'M'). return 13
        if (C = 'n' or C = 'N'). return 14
        if (C = 'o' or C = 'O'). return 15
        if (C = 'p' or C = 'P'). return 16
        if (C = 'q' or C = 'Q'). return 17
        if (C = 'r' or C = 'R'). return 18
        if (C = 's' or C = 'S'). return 19
        if (C = 't' or C = 'T'). return 20
        if (C = 'u' or C = 'U'). return 21
        if (C = 'v' or C = 'V'). return 22
        if (C = 'w' or C = 'W'). return 23
        if (C = 'x' or C = 'X'). return 24
        if (C = 'y' or C = 'Y'). return 25
        if (C = 'z' or C = 'Z'). return 26
        return 0  # Para cualquier otro caracter