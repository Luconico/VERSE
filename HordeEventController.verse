
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level


HordeEventController := class(creative_device):
    # The ID of the controller, used to identify the controller instance in npc_behaviours
    @editable
    ControllerID: int = 1

    # The currency manager used to reward players
    @editable
    CurrenciesManager : CurrencyManager = CurrencyManager{}

    # The type of currency used to reward players
    @editable
    CurrencyType: CurrenciesTextures = CurrenciesTextures.Money

    # The billboard device used to display the wave counter
    @editable
    BillboardHordeCounter : billboard_device = billboard_device{}

    # The damage dealt by NPCs
    @editable
    NPCdamage: float = 10.0

    @editable
    DamageDistance: float = 200.0

    # The number of waves before NPCs start running
    @editable
    WaveNPCstartRUN: int = 5

    # The reward given to players per NPC defeated
    @editable
    var RewardPerDefeat: int = 10

    # The reward addition per difficulty
    @editable
    RewardAdditionPerDifficulty: int = 2

    # The zone where the horde event will take place
    @editable
    HordeFieldMutationZone : mutator_zone_device = mutator_zone_device {}

    # The number of NPCs spawned per cycle
    @editable
    var SpawnPerCycle: int = 2

    # The delay between NPC spawns
    @editable
    var DelayBettwenSpawns: float = 4.0

    # The hardest time to rise difficulty, used to set the minimum delay between spawns
    @editable
    HardestTimeToRise: float = 0.1

    # The time to rise difficulty
    @editable
    var TimeToRiseDifficulty: float = 10.0

    # The effect played when an NPC dies
    @editable
    DeadEffect: ?vfx_spawner_device = false

    # The type of notification displayed when a player defeats an NPC
    @editable
    NotificationType: material_type = material_type.Hearts

    # The spawners used to spawn NPCs
    @editable
    HordeSpawners: []npc_spawner_device = array{}

    var HordeCounter: int = 1

    var SpawnPerCycleTEMP : int = 2
    var DelayBettwenSpawnsTEMP: float = 4.0
    var TimeToRiseDifficultyTEMP: float = 60.0
    var RewardPerDefeatTEMP: int = 10

    var PlayersInZone: [agent]agent = map{}


    Notification : PopupNotification = PopupNotification{}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        SetGlobalHordeControllerInstace(Self)
        # Subscribe to the event when a player enters the zone
        HordeFieldMutationZone.AgentEntersEvent.Subscribe(OnPlayerEnteredZone)
        for (Spawner: HordeSpawners):
            Spawner.EliminatedEvent.Subscribe(OnNPCdead)

    OnNPCdead(Result: device_ai_interaction_result):void=
        # Dead effect on NPC
       TargetAgent:= Result.Target
       if (CastAgent:= TargetAgent?):
            if (FCnpc:= CastAgent.GetFortCharacter[]):
                var NPCTransform : transform = FCnpc.GetTransform()
                if (VFXobject := DeadEffect?, VFXobject.TeleportTo[NPCTransform]):
                    VFXobject.Restart()
        
        # Reward player
        InstigatorAgent:= Result.Source
        if (Player:= InstigatorAgent?, CheckIfAnyPlayerInZone()):
            if (PlayerFC:= Player.GetFortCharacter[]):
                if (PlayerFC.IsActive[]):
                    CurrenciesManager.AddCurrency(Player, CurrencyToString(CurrencyType), RewardPerDefeat)
                    Notification.ShowNotification(Player, RewardPerDefeat, NotificationType)

            
    CheckIfAnyPlayerInZone()<transacts>:logic=
        var isZoneWithPlayers: logic = false
        for (Player: PlayersInZone):
            if (HordeFieldMutationZone.IsInVolume[Player]):
                set isZoneWithPlayers = true

        return isZoneWithPlayers

    OnPlayerEnteredZone(Agent: agent):void=
        # Check if there are any players in the zone
        IsPlayersOnZonePreviosly := CheckIfAnyPlayerInZone()

        # Add player to the list of players in the zone
        if (set PlayersInZone[Agent] = Agent) {}

        # If there are no players in the zone, start the game
        if (not IsPlayersOnZonePreviosly?):
            spawn:
                StartGame()

    SaveInitialStates():void=
        set SpawnPerCycleTEMP = SpawnPerCycle
        set DelayBettwenSpawnsTEMP = DelayBettwenSpawns
        set TimeToRiseDifficultyTEMP = TimeToRiseDifficulty
        set RewardPerDefeatTEMP = RewardPerDefeat                     

    StartGame()<suspends>:void=
        BillboardHordeCounter.SetText(StringToMessage("Ready?"))
        SaveInitialStates()
        Sleep(DelayBettwenSpawns)
        loop:
            IsPlayersInZone:= CheckIfAnyPlayerInZone()
            if (IsPlayersInZone?):
                Print("Players in zone")
                GameLogic()
            else:
                Print("No players in zone")
                ResetGame()
                break

    
    GameLogic()<suspends>:void=
        BillboardHordeCounter.SetText(StringToMessage("Wave: {HordeCounter}"))
        # Spawn NPCs
        for (i:=1..SpawnPerCycle):
            if:
                RandomSpawner:= GetRandomSpawner[],
                CastSpawner:= RandomSpawner?
            then:
                CastSpawner.Spawn()
        
        Sleep(DelayBettwenSpawns)

        # Counter to rise difficulty based on delay between spawns
        set TimeToRiseDifficulty = TimeToRiseDifficulty - DelayBettwenSpawns

        # Rise difficulty
        if (TimeToRiseDifficulty <= 1.0 and DelayBettwenSpawns > HardestTimeToRise):
            set DelayBettwenSpawns = DelayBettwenSpawns - 0.1
            set TimeToRiseDifficulty = TimeToRiseDifficultyTEMP
            set RewardPerDefeat = RewardPerDefeat + RewardAdditionPerDifficulty
            set HordeCounter = HordeCounter + 1
    

    GetRandomSpawner()<decides><transacts>:?npc_spawner_device=
        var RandomSpawner: ?npc_spawner_device = false
        if (HordeSpawners.Length > 0):
            if (ChossedSpawner:= HordeSpawners[GetRandomInt(0, HordeSpawners.Length - 1)]):
                set RandomSpawner = option{ChossedSpawner}

        return RandomSpawner
        
    ResetGame():void=
        for (NPCspawner: HordeSpawners):
            NPCspawner.Reset()
            var dummyAgent: ?agent = false
            NPCspawner.DespawnAll(dummyAgent)
        
        set PlayersInZone = map{}
        set TimeToRiseDifficulty = TimeToRiseDifficultyTEMP
        set DelayBettwenSpawns = DelayBettwenSpawnsTEMP
        set SpawnPerCycle = SpawnPerCycleTEMP
        set HordeCounter = 1
        BillboardHordeCounter.SetText(StringToMessage("Ready?"))
    
    FindNearestTarget(FC : fort_character)<decides><transacts>: fort_character =
        var MaybeTarget : ?fort_character = false
        var CheckRange : float = 5000.0
    
        for (Player: GetPlayspace().GetPlayers(), PlayerFC:= Player.GetFortCharacter[]):
            if:
                DistaceDiference:= Distance(PlayerFC.GetTransform().Translation, FC.GetTransform().Translation) < CheckRange
                not PlayerFC = FC
            then:
                set MaybeTarget = option{PlayerFC}
                set CheckRange = DistaceDiference
        return MaybeTarget?

# Global instances of HordeEventController
var HordeEventControllerInstances: weak_map(session, []HordeEventController) = map{}

SetGlobalHordeControllerInstace(Controller: HordeEventController):void=
    if: 
        HordeEventControllerInstances[GetSession()]
    then:
        if (Current:= HordeEventControllerInstances[GetSession()]):
            var NewArray: []HordeEventController = Current
            set NewArray += array{Controller}
            if (set HordeEventControllerInstances[GetSession()] = NewArray) {}
            Print("Horde controller added")
    else:
        if (set HordeEventControllerInstances[GetSession()] = array{Controller}) {}
        Print("Horde controller setted")
        
GetHordeControllerInstanceByID(ControllerID: int)<decides><transacts>:?HordeEventController=
    var toReturn: ?HordeEventController = false
    if (Instances:= HordeEventControllerInstances[GetSession()]):
        for (Instance: Instances):
            if (Instance.ControllerID = ControllerID):
                set toReturn = option{Instance}
    return toReturn