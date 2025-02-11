using { /Verse.org/Simulation }

# Struct to represent a player's currency balance
PlayerCurrency := struct<persistable>:
    CurrencyID : string
    Amount : int

var playerStats : weak_map(player, player_stats_table) = map{}

# Tracks different persistable stats for each player.
player_stats_table<public> := class<final><persistable>:
    # The version of the current stats table.
    Version : int = 0

    # Total of eliminations the player deal to other players
    Kills : int = 0

    # Total of eliminations got the player by other players
    Eliminations : int = 0

    # Total damage the player deal to their enemies
    TotalDamage : float = 0.0

    # Secrets on the map
    Secrets : []int = array{}

    # Player's currencies
    Currencies : [string]int = map{}

    # Array of unlocked the levels
    UnlockedLevels : []int = array{}


# Creates a new player_stats_table with the same values as the previous player_stats_table.
MakePlayerStatsTable<constructor>(OldTable : player_stats_table)<transacts> := player_stats_table:
    Version := OldTable.Version

    # Transfer values from the old table to the current table

    Kills := OldTable.Kills
    Eliminations := OldTable.Eliminations
    TotalDamage := OldTable.TotalDamage
    Secrets := OldTable.Secrets
    Currencies := OldTable.Currencies
    UnlockedLevels := OldTable.UnlockedLevels

addKill<public>(Agent : agent): void =
    # Get the current stats table for updating the next one
    ContainsPlayerStat := AppearPlayerStats(Agent)

    UpdatePlayerStatsTable(Agent, 
        if (ContainsPlayerStat?):
            # If player stats are present, retrieves and updates the stats table with additional distinctions
            PlayerStatsTable := ProvidePlayerStatsTable(Agent)
        
            player_stats_table {
                MakePlayerStatsTable<constructor>(PlayerStatsTable)
                Kills := PlayerStatsTable.Kills + 1
            }

        # Otherwise, initializes a  stnewats table with the given distinctions.
        else. player_stats_table{ Kills := 1 }
    )

addElimination<public>(Agent : agent): void =
    # Get the current stats table for updating the next one
    ContainsPlayerStat := AppearPlayerStats(Agent)

    UpdatePlayerStatsTable(Agent, 
        if (ContainsPlayerStat?):
            # If player stats are present, retrieves and updates the stats table with additional distinctions
            PlayerStatsTable := ProvidePlayerStatsTable(Agent)
        
            player_stats_table {
                MakePlayerStatsTable<constructor>(PlayerStatsTable)
                Eliminations := PlayerStatsTable.Eliminations + 1
            }

        # Otherwise, initializes a  stnewats table with the given distinctions.
        else. player_stats_table{ Eliminations := 1 }
    )

addDamage<public>(Agent : agent, damage : float): void =
    # Get the current stats table for updating the next one
    ContainsPlayerStat := AppearPlayerStats(Agent)

    UpdatePlayerStatsTable(Agent, 
        if (ContainsPlayerStat?):
            # If player stats are present, retrieves and updates the stats table with additional distinctions
            PlayerStatsTable := ProvidePlayerStatsTable(Agent)
        
            player_stats_table {
                MakePlayerStatsTable<constructor>(PlayerStatsTable)
                TotalDamage := PlayerStatsTable.TotalDamage + damage
            }

        # Otherwise, initializes a  stnewats table with the given distinctions.
        else. player_stats_table{ TotalDamage := damage }
    )

addSecret<public>(Agent : agent, newSecret : int): void =
    # Get the current stats table for updating the next one
    ContainsPlayerStat := AppearPlayerStats(Agent)

    UpdatePlayerStatsTable(Agent, 
        if (ContainsPlayerStat?):
            # If player stats are present, retrieves and updates the stats table with additional distinctions
            PlayerStatsTable := ProvidePlayerStatsTable(Agent)
        
            player_stats_table {
                MakePlayerStatsTable<constructor>(PlayerStatsTable)
                Secrets := PlayerStatsTable.Secrets + array{newSecret}
            }

        # Otherwise, initializes a  stnewats table with the given distinctions.
        else. player_stats_table{ Secrets := array{newSecret} }
    )

hasSecret<public>(Agent : agent, TheSecret : int): logic =
    # Get the current stats table for updating the next one
    ContainsPlayerStat := AppearPlayerStats(Agent)
        if (ContainsPlayerStat?):
            # If player stats are present, retrieves and updates the stats table with additional distinctions
            PlayerStatsTable := ProvidePlayerStatsTable(Agent)
        
            if (PlayerStatsTable.Secrets.Find[TheSecret]). return true
            else . return false
        # Otherwise, initializes a  stnewats table with the given distinctions.
        else. return false

# New function to update currency in player stats
updateCurrency<public>(Agent : agent, CurrencyID : string, Amount : int): void =
    if (Player := player[Agent], not Player.IsActive[]):
        Print("Player disconnected, cancelling")
        return
    ContainsPlayerStat := AppearPlayerStats(Agent)

    UpdatePlayerStatsTable(Agent, 
        if (ContainsPlayerStat?):
            PlayerStatsTable := ProvidePlayerStatsTable(Agent)
            var UpdatedCurrencies : [string]int = map{}
            var CurrencyFound : logic = false

            for (PlayerCurrencyID -> CurrencyAmount : PlayerStatsTable.Currencies):
                if (PlayerCurrencyID = CurrencyID):
                    if (set UpdatedCurrencies[CurrencyID] = Amount):
                        set CurrencyFound = true
                else:
                    if (set UpdatedCurrencies[PlayerCurrencyID] = CurrencyAmount) {}
            
            if (not CurrencyFound?):
                if (set UpdatedCurrencies[CurrencyID] = Amount){}

            player_stats_table {
                MakePlayerStatsTable<constructor>(PlayerStatsTable)
                Currencies := UpdatedCurrencies
            }
        else:
            player_stats_table{ 
                Currencies := map{CurrencyID => Amount}
            }
    )

addUpgrade<public>(Agent : agent, newUpgrade : int): void =
    # Get the current stats table for updating the next one
    ContainsPlayerStat := AppearPlayerStats(Agent)

    UpdatePlayerStatsTable(Agent, 
        if (ContainsPlayerStat?):
            # If player stats are present, retrieves and updates the stats table with additional distinctions
            PlayerStatsTable := ProvidePlayerStatsTable(Agent)
        
            Print("adding upgrade {newUpgrade} to the agent")
            player_stats_table {
                MakePlayerStatsTable<constructor>(PlayerStatsTable)
                UnlockedLevels := PlayerStatsTable.UnlockedLevels + array{newUpgrade}
            }

        # Otherwise, initializes a  stnewats table with the given distinctions.
        else. player_stats_table{ UnlockedLevels := array{newUpgrade} }
    )

    UpdatedPlayerStat := ProvidePlayerStatsTable(Agent)
    Print("Now the player have: {UpdatedPlayerStat.UnlockedLevels.Length}")

hasUpgrade<public>(Agent : agent, theUpgrade : int): logic =
    # Get the current stats table for updating the next one
    ContainsPlayerStat := AppearPlayerStats(Agent)
        if (ContainsPlayerStat?):
            # If player stats are present, retrieves and updates the stats table with additional distinctions
            PlayerStatsTable := ProvidePlayerStatsTable(Agent)
        
            if (PlayerStatsTable.UnlockedLevels.Find[theUpgrade]). return true
            else . return false
        # Otherwise, initializes a  stnewats table with the given distinctions.
        else. return false
        
getUnlockedLevelsNumber<public>(Agent: agent): int =
    var unlockedLevels: int = 1
    UpdatedPlayerStat := ProvidePlayerStatsTable(Agent)
    set unlockedLevels = UpdatedPlayerStat.UnlockedLevels.Length
    return unlockedLevels

# Checks if the stats table is available for the given agent and returns true if present, otherwise false.
AppearPlayerStats<public>(Agent : agent) : logic = 
    if (
        InPlayer := player[Agent]
        PlayerStatsTable := playerStats[InPlayer]
    ). true else. false

<#
    Retrieves the player statistics table from the PlayerMap for the given player (InPlayer). 
    If the table is not already present, it creates a new entry in PlayerMap with an empty 
    player statistics table and then returns this newly created table.
#>
ProvidePlayerStatsTable<public>(Agent : agent) : player_stats_table =
    # Check if the value is present in the table map
    if (
        InPlayer := player[Agent]
        PlayerStatsTable := playerStats[InPlayer]
    ). return PlayerStatsTable
    player_stats_table{}

# Updates the player statistics table with data from the specified agent.
UpdatePlayerStatsTable<internal>(Agent : agent, StatsTable : player_stats_table): void =
    #Print("Trying to save a new persistent player stats table...")

    if:
        InPlayer := player[Agent]
        set playerStats[InPlayer] = StatsTable

        #Print("The player stats table has been updated succesfully.")
