using { Utils }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Assets }
using { /Verse.org/Simulation }

CurrenciesTextures := enum:
    #Añadir identificadores necesarios para texturiazados.
    Hearts
    Money
    Disabled

CurrencyToString(Currency : CurrenciesTextures) : string =
    return case(Currency):
        CurrenciesTextures.Money => "Money"
        CurrenciesTextures.Hearts => "Hearts"
        CurrenciesTextures.Disabled => "Disabled"
        
StringToCurrency(Currency : string) : CurrenciesTextures =
    return case(Currency):
        "Money" => CurrenciesTextures.Money
        "Hearts" => CurrenciesTextures.Hearts
        "Disabled" => CurrenciesTextures.Disabled
        _ => CurrenciesTextures.Disabled

StringToCurrencyMaterial(Currency : string) : material_type =
    return case(Currency):
        "Money" => material_type.Money
        "Hearts" => material_type.Hearts
        "Disabled" => material_type.Money
        _ => material_type.Money
        
# Struct to represent a currency
CurrenciesList := class<concrete>:
    @editable
    ID : string = "Money"

    @editable
    Name : string = "Money"

    @editable
    Prefix : string = ""

    @editable
    InitialAmount : int = 0

    @editable
    ShowWidget : logic = false

    @editable
    Texture : CurrenciesTextures = CurrenciesTextures.Money

    @editable
    TextOffset : float = 15.0


# Class to manage player currencies
CurrencyManager := class(creative_device):
    # List of available currencies
    @editable
    Currencies : []CurrenciesList = array{}

    # El Manager principal
    var Manager : ?TycoonManager = false

    # Map to store UI interfaces per player
    var CurrencyInterfaces : [player]currency_display_interface = map{}

    # Initialize currencies for a player
    InitializePlayerCurrencies(Player : agent, _Manager : TycoonManager) : void =
        PlayerData := ProvidePlayerStatsTable(Player)

        for (Currency : Currencies):
            if (CurrencyData := PlayerData.Currencies[Currency.ID]):
                updateCurrency(Player, Currency.ID, CurrencyData)
                UpdateCurrencyUI(Player, Currency.ID, CurrencyData)
            else:
                updateCurrency(Player, Currency.ID, Currency.InitialAmount)
                UpdateCurrencyUI(Player, Currency.ID, Currency.InitialAmount)

        set Manager = option{_Manager}

        # Initialize UI if needed
        if (ThePlayer := player[Player]):
            CreateCurrencyInterface(ThePlayer)

    GetCurrencyList<public>():[]string=
        var Result : []string = array{}
        for (Currency : Currencies):
            set Result += array{Currency.Name}
        return Result

    GetCurrencyTexture<public>(Input: CurrenciesTextures):texture = case(Input){
        CurrenciesTextures.Money => Textures.money_background
        CurrenciesTextures.Hearts => Textures.heart_background
        _ => Textures.money_background
    }

    # Set the amount of a specific currency for a player
    SetCurrency(Player : agent, CurrencyID : string, Amount : int) : void =
        updateCurrency(Player, CurrencyID, Amount)
        UpdateCurrencyUI(Player, CurrencyID, Amount)

    # Add to the amount of a specific currency for a player
    AddCurrency(Player : agent, CurrencyID : string, Amount : int) : void =
        CurrentAmount := GetCurrencyAmount(Player, CurrencyID)
        updateCurrency(Player, CurrencyID, CurrentAmount + Amount)
        UpdateCurrencyUI(Player, CurrencyID, CurrentAmount + Amount)

    # Remove from the amount of a specific currency for a player
    RemoveCurrency(Player : agent, CurrencyID : string, Amount : int) : void =
        CurrentAmount := GetCurrencyAmount(Player, CurrencyID)
        NewAmount := Max(CurrentAmount - Amount, 0)
        updateCurrency(Player, CurrencyID, NewAmount)
        UpdateCurrencyUI(Player, CurrencyID, NewAmount)

    # Check if a player has enough of a specific currency
    CheckCurrency(Player : agent, CurrencyID : string, Amount : int) : logic =
        # Get the player stats table directly in the transactional context
        PlayerStatsTable := ProvidePlayerStatsTable(Player)
        for (PlayerCurrencyID -> CurrencyAmount : PlayerStatsTable.Currencies):
            if (PlayerCurrencyID = CurrencyID and CurrencyAmount >= Amount):
                return true
        return false

    # Check and remove currency if the player has enough
    CheckAndRemoveCurrency(Player : agent, CurrencyID : string, Amount : int) : logic =
        haveCurrencty := CheckCurrency(Player, CurrencyID, Amount)
        if (haveCurrencty?):
            RemoveCurrency(Player, CurrencyID, Amount)
            return true
        return false

    # Get the current amount of a specific currency for a player
    GetCurrencyAmount(Player : agent, CurrencyID : string) : int =
        PlayerStatsTable := ProvidePlayerStatsTable(Player)
            for (PlayerCurrencyID -> CurrencyAmount : PlayerStatsTable.Currencies):
                if (PlayerCurrencyID = CurrencyID):
                    return CurrencyAmount
        return 0

    # Create and show currency interface for a player
    CreateCurrencyInterface(Player : player):void =
        if (not CurrencyInterfaces[Player]):
            NewInterface := currency_display_interface{
                Player := Player
                Manager := Self
            }
            if (set CurrencyInterfaces[Player] = NewInterface):
                NewInterface.AddGameplayUI()

    # Update the UI display for a currency
    UpdateCurrencyUI(Player : agent, CurrencyID : string, Amount : int):void =
        if (ThePlayer := player[Player], Interface := CurrencyInterfaces[ThePlayer]):
            Interface.UpdateCurrencyDisplay(CurrencyID, Amount)
