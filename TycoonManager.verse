using { /Verse.org/Colors }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Concurrency }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { Array }
using { Utils }

StringToMessage<localizes><internal>(String : string): message = "{String}"

# Enum para definir el tipo de movimiento del objeto
MovementType := enum:
    None
    FromDown
    FromTop

# Enum para representar los diferentes tipos de errores que pueden ocurrir
PlotError := enum:
    Success
    PlayerAlreadyHasPlot
    PlotOccupied
    InvalidPlotIndex
    PlayerNotFound
    PlotNotFound
    InvalidPlayer

# Sistema ATM para manejar las transacciones
ATMSystem := class<concrete>:
    @editable
    Billboard : billboard_device = billboard_device{}

    @editable
    TriggerATM : trigger_device = trigger_device{}

    @editable
    VFXWithdraw : ?vfx_spawner_device = false

    # El Manager principal
    var Manager : ?TycoonManager = false

    # El agente dueño del ATM
    var Owner : ?agent = false

    var TaskHandle : ?cancelable = false

    # Inicializa el ATM con las referencias necesarias
    Init(_Manager : TycoonManager, _Owner : agent):void =
        set Manager = option{_Manager}
        set Owner = option{_Owner}
        SetupATMTrigger()
        spawn { UpdateBillboardLoop() }

    UpdateOwner(_Owner : agent):void=
        set Owner = option{_Owner}
        spawn { UpdateBillboardLoop() }

    # Configura el trigger del ATM
    SetupATMTrigger():void =
        TriggerATM.Enable()
        set TaskHandle = option{TriggerATM.TriggeredEvent.Subscribe(HandleATMTrigger)}

    # Maneja cuando el jugador activa el trigger del ATM
    HandleATMTrigger(MaybeAgent : ?agent):void =
        if (Agent := MaybeAgent?, MainManager := Manager?, ATMOwner := Owner?):
            # Solo permitir al dueño del ATM retirar dinero
            if (Agent = ATMOwner):
                # Obtener el balance actual del ATM
                ATMBalance := MainManager.CurrenciesManager.GetCurrencyAmount(Agent, "MoneyATM")
                if (ATMBalance > 0):
                    # Transferir el dinero del ATM a la billetera
                    MainManager.CurrenciesManager.AddCurrency(Agent, "Money", ATMBalance)
                    MainManager.CurrenciesManager.SetCurrency(Agent, "MoneyATM", 0)

                    MaybePlayerSpace := MainManager.GetPlayerPlayspace(Agent)
                    if (PlayerSpace := MaybePlayerSpace?):
                        PlayerSpace.Notification.ShowNotification(Agent, ATMBalance, material_type.Money)
                    
                    # Efecto visual si está configurado
                    var TriggerTransform : transform = TriggerATM.GetTransform()
                    set TriggerTransform.Translation = TriggerTransform.Translation + vector3 { Z := 20.0 }

                    if (WithdrawVFX := VFXWithdraw?, WithdrawVFX.TeleportTo[TriggerTransform]):
                        WithdrawVFX.Restart()
                        
                    Print("Withdrawn ${ATMBalance} from ATM")

    # Actualiza el billboard con el balance actual
    UpdateBillboardLoop()<suspends>:void =
        loop:
            Sleep(1.0)
            if (ATMOwner := Owner?):
                UpdateBillboard()
            else:
                break

    # Actualiza el texto del billboard
    UpdateBillboard():void =
        if (MainManager := Manager?, ATMOwner := Owner?):
            ATMBalance := MainManager.CurrenciesManager.GetCurrencyAmount(ATMOwner, "MoneyATM")
            Billboard.SetText(StringToMessage("${FormatCurrency(ATMBalance)}"))

    # Limpia los recursos cuando se destruye el ATM
    Cleanup():void =
        set Owner = false
        Billboard.SetText(StringToMessage("$0"))
        if (CancelTask := TaskHandle?):
            CancelTask.Cancel()
        TriggerATM.Disable()

play_level_action := enum {
    None,
    PetsLogic
}

PlayLevel := class<concrete>:

    @editable
    LevelID : string = "LevelID"

    @editable
    controller : creative_prop = creative_prop{}

    @editable
    trigger : trigger_device = trigger_device{}

    @editable
    UnlockAfter : []string = array{}

    @editable
    UnlockPrice : int = 0

    @editable
    UnlockCurrency : string = "Money"

    @editable
    UnlockBenefits : int = 1

    @editable
    UnlockCinematic : cinematic_sequence_device = cinematic_sequence_device{}

    @editable
    LevelDropper : ?dropper_device = false

    var isUnlocked : logic = false

    @editable
    MovementStyle : MovementType = MovementType.None

    # Offset para las animaciones desde arriba/abajo
    YOffset : float = 500.0

    # Duración de la animación en segundos
    AnimationDuration : float = 2.0

    var InitialControllerTransform : transform = transform{}
    var InitialTriggerOffset : vector3 = vector3{}
    var InitialTriggerRotation : rotation = rotation{}

    # Inicia la secuencia de aparición del nivel
    InitializeLevel(ClaimPosition : vector3, ClaimRotation : rotation)<suspends>:void =
        # Posición base para el controlador
        BasePosition := ClaimPosition
        HideTrigger()

        Sleep(0.5)
        
        # Ajuste de posición según el tipo de movimiento
        case (MovementStyle):
            MovementType.None =>
                if (controller.TeleportTo[BasePosition, ClaimRotation]) {}
            MovementType.FromDown =>
                StartPosition := vector3{
                    X := BasePosition.X
                    Y := BasePosition.Y
                    Z := BasePosition.Z - YOffset
                }
                if (controller.TeleportTo[StartPosition, ClaimRotation]) {}
                controller.MoveTo(BasePosition, ClaimRotation, AnimationDuration)
            MovementType.FromTop =>
                StartPosition := vector3{
                    X := BasePosition.X
                    Y := BasePosition.Y
                    Z := BasePosition.Z + YOffset
                }
                if (controller.TeleportTo[StartPosition, ClaimRotation]) {}
                controller.MoveTo(BasePosition, ClaimRotation, AnimationDuration)

    # Nueva función para mover el trigger a su posición en la nueva ubicación
    UnlockTriggerAt(ClaimTransform : transform):void =
        # Obtener transformaciones absolutas
        ControllerTransform := controller.GetTransform()
        TriggerTransform := trigger.GetTransform()
            
        # 1. Calcular el offset relativo entre el controller y el trigger
        RelativePosition := TriggerTransform.Translation - ControllerTransform.Translation
        RelativeRotation := TriggerTransform.Rotation.UnrotateBy(ControllerTransform.Rotation)

        # 2. Aplicar ese offset a la posición del ClaimTransform
        NewPosition := ClaimTransform.Translation + RelativePosition
        NewRotation := ClaimTransform.Rotation.RotateBy(RelativeRotation)

        # 3. Teleportar el trigger a la nueva posición
        if (trigger.TeleportTo[NewPosition, NewRotation]):
            trigger.Enable()
            Print("Trigger reposicionado para nivel {LevelID}")
            Print("Posición original del trigger: {TriggerTransform.Translation}")
            Print("Posición del controller: {ControllerTransform.Translation}")
            Print("Offset calculado: {RelativePosition}")
            Print("Nueva posición: {NewPosition}")

    # Oculta el trigger actual moviéndolo lejos
    HideTrigger():void =
        TriggerTransform := trigger.GetTransform()
        HidePosition := TriggerTransform.Translation + vector3{Z := -5000.0}
        trigger.Disable()
        if (trigger.TeleportTo[HidePosition, rotation{}]) {}

        Print("Nueva posición de ocultacion: {HidePosition} ID = {LevelID}")

    # Called when the level is first set up
    SaveInitialPositions():void =
        # Store initial transforms
        set InitialControllerTransform = controller.GetTransform()
        
        # Calculate and store relative trigger position
        TriggerTransform := trigger.GetTransform()
        set InitialTriggerOffset = TriggerTransform.Translation - InitialControllerTransform.Translation
        set InitialTriggerRotation = TriggerTransform.Rotation

    # New function to restore original positions
    RestoreOriginalPositions():void =
        # First restore controller
        if (controller.TeleportTo[InitialControllerTransform.Translation, InitialControllerTransform.Rotation]):
            # Calculate new trigger position
            if (trigger.TeleportTo[InitialControllerTransform.Translation + InitialTriggerOffset, InitialTriggerRotation]) {}

# Estructura para mantener información del trigger
TriggerInfo := struct:
    Subscription : cancelable
    LevelID : string

# Información de la parcela y su estado
PlayerPlayspace := class<concrete>:
    var OwnerId : ?agent = false
    var IsOccupied : logic = false

    # Referencia al TycoonManager principal
    var Manager : ?TycoonManager = false

    @editable
    ClaimSpace : mutator_zone_device = mutator_zone_device{}

    @editable
    Indicator : objective_device = objective_device{}

    @editable
    BoughtVFX : ?vfx_spawner_device = false

    @editable
    ClearPlayspace : button_device = button_device{}

    @editable
    PlayLevels : []PlayLevel = array{}

    @editable
    ATM : ATMSystem = ATMSystem{}

    @editable
    SpawnPoint : transform = transform{}

    @editable
    LevelOrigin : transform = transform{}

    @editable
    AFK_Zone: AFK_zone = AFK_zone{}

    @editable
    TriggerCounter : trigger_device = trigger_device{}

    @editable
    AwardCounter : accolades_device = accolades_device{}

    @editable
    DoorBarrier: barrier_device = barrier_device{}

    Notification : PopupNotification = PopupNotification{}

    # Lista de suscripciones activas
    var ActiveSubscriptions : []TriggerInfo = array{}

    # Constructor para inicializar con el Manager
    Init(_Manager : TycoonManager):void =
        set Manager = option{_Manager}

    InitializeAFKZone():void =
        AFK_Zone.ChairDevice.SeatedEvent.Subscribe(AFK_Zone.OnEnter)
        AFK_Zone.ChairDevice.ExitedEvent.Subscribe(AFK_Zone.OnLeave)

    # Inicializa el primer nivel cuando se reclama la parcela
    InitializeFirstLevel():void =
        if (FirstLevel := PlayLevels[0]):
            for (Level : PlayLevels):
                Level.SaveInitialPositions()

            # Obtener posición y rotación del ClaimSpace
            ClaimTransform := ClaimSpace.GetTransform()
            #FirstLevel.InitializeLevel(ClaimTransform.Translation, ClaimTransform.Rotation)
            SetupTriggerForLevel(FirstLevel)


            #Intialization of a MAIN ATM
            if (Owner := OwnerId?, MainManager := Manager?):
                ATM.Init(MainManager, Owner)
                DoorBarrier.AddToIgnoreList(Owner)
            #Inicialization of AFK zone
            InitializeAFKZone()

            #Spawn money passive benefits
            spawn { BenefitsLoop() }

    # Loop principal para los beneficios
    BenefitsLoop()<suspends>:void =
        loop:
            if (not IsOccupied?):
                break
            if (Owner := OwnerId?, MainManager := Manager?):
                Sleep(1.0)
                DistributeBenefits()

    # Función para filtrar niveles desbloqueados
    IsLevelUnlocked(Level : PlayLevel)<transacts><decides>:void =
        if (Level.isUnlocked?):
            true    # Retorna si está desbloqueado
        false         # Falla si está bloqueado

    # Distribuir los beneficios acumulados
    DistributeBenefits():void =
        if (Owner := OwnerId?, MainManager := Manager?):
            var TotalBenefits : int = 0
            # Ahora solo suma los beneficios de niveles desbloqueados
            for (Level : PlayLevels):
                if (Level.isUnlocked?):
                    set TotalBenefits += Level.UnlockBenefits

            if (TotalBenefits > 0):
                #Print("Adding ${TotalBenefits} to the ATM")
                set TotalBenefits = TotalBenefits * AFK_Zone.GetCurrentMultiplier()
                CurrentMoney : int = MainManager.CurrenciesManager.GetCurrencyAmount(Owner, "Money")
                MainManager.CurrenciesManager.AddCurrency(Owner, "MoneyATM", TotalBenefits)

    # Para debug, puedes agregar:
    PrintLevelsStatus():void =
        for (Level : PlayLevels):
            if (Level.isUnlocked?):
                Print("Level {Level.LevelID}: Unlocked = true, Benefits = {Level.UnlockBenefits}")
            else:
                Print("Level {Level.LevelID}: Unlocked = false, Benefits = {Level.UnlockBenefits}")


    # Configura el evento para el trigger de un nivel
    SetupTriggerForLevel(Level : PlayLevel):void =
        Level.trigger.Enable()
        TriggerSubscription := Level.trigger.TriggeredEvent.Subscribe(event_handler(?agent, PlayLevel) { 
                StaticParam := Level,
                OnActorPerform := HandleLevelTrigger
            }.InternalActorEvent)
        set ActiveSubscriptions = ActiveSubscriptions + array{TriggerInfo{
            Subscription := TriggerSubscription,
            LevelID := Level.LevelID
        }}
        Print("Trigger configurado para nivel {Level.LevelID}")

    # Busca y cancela la suscripción para un levelID específico
    RemoveSubscriptionForLevel(LevelID : string):void =
        var NewSubscriptions : []TriggerInfo = array{}
        
        for (iTrigger : ActiveSubscriptions):
            if (iTrigger.LevelID = LevelID):
                iTrigger.Subscription.Cancel()
            else:
                set NewSubscriptions = NewSubscriptions + array{iTrigger}
        
        set ActiveSubscriptions = NewSubscriptions

    OnTestAward2(Agent : agent):void=
        Print("testAward2")

    # Función específica para manejar el evento del trigger
    HandleLevelTrigger(MaybeAgent : ?agent, Level : PlayLevel):void =
    
        if (Agent := MaybeAgent?, MainManager := Manager?):

            # Acceder al CurrenciesManager a través del Manager
            Bought := MainManager.CurrenciesManager.CheckAndRemoveCurrency(Agent, Level.UnlockCurrency, Level.UnlockPrice)
            
            if (Bought? or Level.UnlockPrice = 0):
                Level.UnlockCinematic.Play()
                var TriggerTransform : transform = Level.trigger.GetTransform()
                set TriggerTransform.Translation = TriggerTransform.Translation + vector3 { Z := 20.0 }
                
                if (BuyVFX := MainManager.BoughtVFX?):
                    if (BuyVFX.TeleportTo[TriggerTransform]):
                        BuyVFX.Restart()
                else if (BuyVFX := BoughtVFX?):
                    if (BuyVFX.TeleportTo[TriggerTransform]):
                        BuyVFX.Restart()
                MainManager.BoughtAudio.Play(Agent)
                

                Print("Nivel {Level.LevelID} activado")
                TriggerCounter.Trigger(Agent)
                AwardCounter.TestAwardEvent.Subscribe(OnTestAward2)
                
                set Level.isUnlocked = true
                ClaimTransform := ClaimSpace.GetTransform()
                spawn{Level.InitializeLevel(ClaimTransform.Translation, ClaimTransform.Rotation)}
                if (Dropper := Level.LevelDropper?):
                    Dropper.SetCurrencyManager(MainManager.CurrenciesManager)
                    spawn{InitDropper(Dropper)}
                spawn { UnlockNextLevels(Agent, Level.LevelID) }

                MainManager.SaveUnlockedLevel(Agent, Level.LevelID)
            else:
                Print("No tienes suficiente dinero")
                MainManager.HUBdevice.Show(Agent)

    InitDropper(Dropper: dropper_device)<suspends>:void =
        Sleep(2.0)
        Print("Inicializando Dropper para la parcela")
        Dropper.InitializePOwnerID(OwnerId)
        Dropper.InitializeDropper()

    # Desbloquea los siguientes niveles basados en UnlockAfter
    UnlockNextLevels(Agent : agent, CurrentLevelID : string)<suspends>:void =
        # Primero, ocultamos el trigger del nivel actual
        #HideTriggerForLevel(CurrentLevelID)
        
        MaybeLevel := FindLevelByID(CurrentLevelID)
        if (CurrentLevel := MaybeLevel?):
            # Eliminar suscripción del nivel actual
            RemoveSubscriptionForLevel(CurrentLevelID)

            ClaimTransform := ClaimSpace.GetTransform()

            # Desbloquear los nuevos niveles
            for (Index -> LevelID : CurrentLevel.UnlockAfter):
                Level := FindLevelByID(LevelID)
                if (NextLevel := Level?):
                    # Solo movemos el trigger a su nueva posición
                    NextLevel.UnlockTriggerAt(ClaimTransform)
                    SetupTriggerForLevel(NextLevel)

                    if (Index = 0):
                        TriggerTransform := NextLevel.trigger.GetTransform()
                        if (Indicator.TeleportTo[TriggerTransform.Translation, TriggerTransform.Rotation]) {}
                        Indicator.ActivateObjectivePulse(Agent)

    # Inicializa un nivel específico por su ID
    InitializeNextLevel(LevelID : string, Agent : agent)<suspends>:void =
        for (Index -> Level : PlayLevels):
            if (Level.LevelID = LevelID):
                ClaimTransform := ClaimSpace.GetTransform()
                #Level.InitializeLevel(ClaimTransform.Translation, ClaimTransform.Rotation)
                SetupTriggerForLevel(Level)

    # Limpia todas las suscripciones activas
    CleanupTriggers():void =
        for (iTrigger : ActiveSubscriptions):
            iTrigger.Subscription.Cancel()
        set ActiveSubscriptions = array{}

    # Nueva función para encontrar un nivel por su ID
    FindLevelByID(LevelID : string):?PlayLevel =
        for (Level : PlayLevels):
            if (Level.LevelID = LevelID):
                return option{Level}
        return false

    # Nueva función para ocultar el trigger de un nivel específico
    HideTriggerForLevel(LevelID : string):void =
        MaybeLevel := FindLevelByID(LevelID)
        if (Level := MaybeLevel?):
            Level.HideTrigger()
            Print("Trigger oculto para el nivel {LevelID}")

    Cleanup():void =
        # Reset owner and occupation status  
        set OwnerId = false
        set IsOccupied = false
    
        # Clean ATM system
        ATM.Cleanup()
    
        # Hide indicator icon
        Indicator.Hide()
    
        # Reset all levels to initial state and positions
        for (Level : PlayLevels):
            set Level.isUnlocked = false
            Level.RestoreOriginalPositions()
    
        # Clean up active trigger subscriptions
        CleanupTriggers()

# Estructura para el resultado de operaciones de parcela
PlotResult := struct:
    Success : logic
    ErrorType : PlotError
    Message : string
    PlotIndex : ?int = false

reward_zones:= class():
    @editable
    MutatorZone : mutator_zone_device = mutator_zone_device{}

    @editable
    CurrencyType: CurrenciesTextures = CurrenciesTextures.Money

    @editable
    RewardPrice : int = 0

    Notification : PopupNotification = PopupNotification{}

    var CurrenciesManager : CurrencyManager = CurrencyManager{}

    Init(_Manager : CurrencyManager):void =
        set CurrenciesManager = _Manager

    OnEnter(Agent: agent):void=
        CurrenciesManager.AddCurrency(Agent, CurrencyToString(CurrencyType), RewardPrice)
        Notification.ShowNotification(Agent, RewardPrice, material_type.Money)

trigger_rewards:= class():
    @editable
    RewardTrigger : trigger_device = trigger_device{}

    @editable
    CurrencyType: CurrenciesTextures = CurrenciesTextures.Money

    @editable
    RewardPrice : int = 0

    Notification : PopupNotification = PopupNotification{}

    var CurrenciesManager : CurrencyManager = CurrencyManager{}

    Init(_Manager : CurrencyManager):void =
        set CurrenciesManager = _Manager

    OnEnter(Agent: ?agent):void=
        if (CastAgent := Agent?):
            CurrenciesManager.AddCurrency(CastAgent, CurrencyToString(CurrencyType), RewardPrice)
            Notification.ShowNotification(CastAgent, RewardPrice, StringToCurrencyMaterial(CurrencyToString(CurrencyType)))

AFK_zone:= class():
    @editable
    ChairDevice : chair_device = chair_device{}

    @editable
    AFK_Multiplier : int = 5

    var currentMultiplier : int = 1

    OnEnter(Agent: agent):void=
        Print("AFK multiplier applied")
        set currentMultiplier = AFK_Multiplier
    
    OnLeave(Agent: agent):void=
        Print("AFK multiplier removed")
        set currentMultiplier = 1
    
    GetCurrentMultiplier():int=
        return currentMultiplier


TycoonManager := class(creative_device):
    # Mapa de parcelas disponibles
    @editable
    var PlayerPlayspaces : []PlayerPlayspace = array{}

    @editable
    CurrenciesManager : CurrencyManager = CurrencyManager{}

    @editable
    BoughtVFX : ?vfx_spawner_device = false

    @editable
    BoughtAudio: audio_player_device = audio_player_device{}

    @editable
    RewardZones: []reward_zones = array{}

    @editable
    RewardTriggers: []trigger_rewards = array{}

    @editable
    HUBdevice : hud_message_device = hud_message_device{}

    # Eventos
    PlayspaceAssignedEvent : event(tuple(agent, int)) = event(tuple(agent, int)){}
    PlayspaceRevokedEvent : event(tuple(agent, int)) = event(tuple(agent, int)){}
    PlotOperationFailedEvent : event(tuple(agent, PlotError, string)) = event(tuple(agent, PlotError, string)){}

    OnBegin<override>()<suspends>:void =
        # Suscribirse a eventos de jugador
        InitializePlayspaces()
        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerLeft)
        SetupTriggers()
        InitializeRewardZones()
        InitializeRewardTriggers()
    
    InitializeRewardZones():void =
        for (RewardZone : RewardZones):
            RewardZone.Init(CurrenciesManager)
            RewardZone.MutatorZone.AgentEntersEvent.Subscribe(RewardZone.OnEnter)

    InitializeRewardTriggers():void =
        for (RewardTrigger : RewardTriggers):
            RewardTrigger.Init(CurrenciesManager)
            RewardTrigger.RewardTrigger.TriggeredEvent.Subscribe(RewardTrigger.OnEnter)

     # Inicializar cada PlayerPlayspace con la referencia al Manager
    InitializePlayspaces():void =
        for (Playspace : PlayerPlayspaces):
            Playspace.Init(Self)
            Playspace.ClearPlayspace.InteractedWithEvent.Subscribe(ReleasePlot)

    # Configurar los triggers para cada parcela
    SetupTriggers():void =
        for (Index -> Playspace : PlayerPlayspaces):
            if (Index >= 0 and Index < PlayerPlayspaces.Length):
                Print("Inicializando Parcela #{Index}")
                Playspace.ClaimSpace.AgentEntersEvent.Subscribe(event_handler(agent, int) { 
                    StaticParam := Index, 
                    OnActorPerform := OnTriggerActivated
                }.InternalActorEvent)
            else:
                Print("Error: Índice de parcela inválido durante la configuración: {Index}")

    # Validar el índice de una parcela
    ValidatePlotIndex(Index:int):PlotResult =
        if (Index < 0 or Index >= PlayerPlayspaces.Length):
            return PlotResult{
                Success := false
                ErrorType := PlotError.InvalidPlotIndex
                Message := "Índice de parcela fuera de rango: {Index}"
            }
        
        if (Plot := PlayerPlayspaces[Index]):
            return PlotResult{
                Success := true
                ErrorType := PlotError.Success
                Message := "Índice de parcela válido"
                PlotIndex := option{Index}
            }
            
        return PlotResult{
            Success := false
            ErrorType := PlotError.PlotNotFound
            Message := "No se pudo acceder a la parcela: {Index}"
        }

    # Validar un jugador
    ValidatePlayer(Agent:agent):PlotResult =
        if (Player := player[Agent]):
            return PlotResult{
                Success := true
                ErrorType := PlotError.Success
                Message := "Jugador válido"
            }
        
        return PlotResult{
            Success := false
            ErrorType := PlotError.PlayerNotFound
            Message := "No se pudo obtener el jugador del agente"
        }

    # Intenta asignar una parcela específica a un jugador con validaciones mejoradas
    ClaimPlot(Index:int, Agent:agent):PlotResult =
        # Validar el jugador
        PlayerValidation := ValidatePlayer(Agent)
        if (not PlayerValidation.Success?):
            PlotOperationFailedEvent.Signal(Agent, PlayerValidation.ErrorType, PlayerValidation.Message)
            return PlayerValidation

        # Validar el índice de la parcela
        PlotValidation := ValidatePlotIndex(Index)
        if (not PlotValidation.Success?):
            PlotOperationFailedEvent.Signal(Agent, PlotValidation.ErrorType, PlotValidation.Message)
            return PlotValidation

        # Verificar si el jugador ya tiene una parcela
        if (HasPlot(Agent)?):
            var Result : PlotResult = PlotResult{
                Success := false
                ErrorType := PlotError.PlayerAlreadyHasPlot
                Message := "El jugador ya tiene una parcela asignada"
            }
            PlotOperationFailedEvent.Signal(Agent, Result.ErrorType, Result.Message)
            return Result

        # Verificar si la parcela está disponible
        if (Plot := PlayerPlayspaces[Index]):
            if (Plot.IsOccupied?):
                var Result : PlotResult = PlotResult{
                    Success := false
                    ErrorType := PlotError.PlotOccupied
                    Message := "La parcela {Index} ya está ocupada"
                }
                PlotOperationFailedEvent.Signal(Agent, Result.ErrorType, Result.Message)
                return Result

            # Asignar la parcela
            if (set PlayerPlayspaces[Index].IsOccupied = true, set PlayerPlayspaces[Index].OwnerId = option{Agent}):
                Plot.InitializeFirstLevel()

                # Cargamos los niveles guardados después de inicializar
                spawn { LoadUnlockedLevels(Agent, Plot) }


                #Initialization of currencies for the player.
                CurrenciesManager.InitializePlayerCurrencies(Agent, Self)
                PlayspaceAssignedEvent.Signal(Agent, Index)
                return PlotResult{
                    Success := true
                    ErrorType := PlotError.Success
                    Message := "Parcela {Index} asignada exitosamente"
                    PlotIndex := option{Index}
                }

        return PlotResult{
            Success := false
            ErrorType := PlotError.PlotNotFound
            Message := "Error al asignar la parcela {Index}"
        }

    # Libera la parcela de un jugador con validaciones mejoradas
    ReleasePlot(Agent:agent):PlotResult =
        # Validar el jugador
        Print("Release executed")
        PlayerValidation := ValidatePlayer(Agent)
        if (not PlayerValidation.Success?):
            PlotOperationFailedEvent.Signal(Agent, PlayerValidation.ErrorType, PlayerValidation.Message)
            return PlayerValidation

        Print("Validated")

        # Obtener el índice de la parcela del jugador
        if (LevelIndex := GetPlayerPlotIndex(Agent)?):
            Print("Found level index: {LevelIndex}")
            if (Plot := PlayerPlayspaces[LevelIndex]):
                Print("Found plot")
                # Clean up the plot
                Plot.Cleanup()
                Print("Clearing area")
                PlayspaceRevokedEvent.Signal(Agent, LevelIndex)
                PlayerStatsTable := ProvidePlayerStatsTable(Agent)
                Print("Cargando niveles para el jugador.")
                
                # Primero procesamos todos los niveles guardados
                Print("Found: {PlayerStatsTable.UnlockedLevels.Length} unlocked levels.")
                return PlotResult{
                    Success := true
                    ErrorType := PlotError.Success
                    Message := "Parcela {LevelIndex} liberada exitosamente"
                    PlotIndex := option{LevelIndex}
                }

        var Result : PlotResult = PlotResult{
            Success := false
            ErrorType := PlotError.PlotNotFound
            Message := "El jugador no tiene una parcela asignada"
        }
        PlotOperationFailedEvent.Signal(Agent, Result.ErrorType, Result.Message)
        return Result

    # Guarda un nivel desbloqueado para un jugador
    SaveUnlockedLevel(Agent:agent, LevelID:string):void =
        if (Player := player[Agent]):
            ContainsPlayerStat := AppearPlayerStats(Agent)
            LevelHash := StringToLevelID(LevelID)

            Print("Starting saving the level: {LevelID} con HASH: {LevelHash}")

            checkUpgrade := hasUpgrade(Agent, LevelHash)
            if (not checkUpgrade?):
                addUpgrade(Agent, LevelHash)

    IntToLevelID(Hash:int):?string =
        var AllLevels : []string = array{}
        if (Playspace := PlayerPlayspaces[0]):
            for (Level : Playspace.PlayLevels):
                set AllLevels += array{Level.LevelID}
        
        for (Level : AllLevels):
            LevelHash := StringToLevelID(Level)
            Print("Checking {LevelHash} with {Hash}")
            if (LevelHash = Hash):
                return option{Level}
                
        return false

    # Carga y restaura los niveles desbloqueados para un jugador
    LoadUnlockedLevels(Agent:agent, Plot:PlayerPlayspace)<suspends>:void =
        if (Player := player[Agent]):
            PlayerStatsTable := ProvidePlayerStatsTable(Agent)
            Print("Cargando niveles para el jugador.")
            
            # Primero procesamos todos los niveles guardados
            Print("Found: {PlayerStatsTable.UnlockedLevels.Length} unlocked levels.")
            for (LevelHash : PlayerStatsTable.UnlockedLevels):
                Print("Loading {LevelHash} level")
                InLevelID := IntToLevelID(LevelHash)
                if (LevelID := InLevelID?):
                    FoundLevel := Plot.FindLevelByID(LevelID)
                    if (Level := FoundLevel?):
                        # Marcamos el nivel como desbloqueado
                        set Level.isUnlocked = true
                        
                        # Inicializamos el nivel sin activar triggers
                        ClaimTransform := Plot.ClaimSpace.GetTransform()
                        Level.InitializeLevel(ClaimTransform.Translation, ClaimTransform.Rotation)
                        
                        Print("Nivel restaurado: {LevelID}")
                    else:
                        Print("The level: {LevelID} is not founded")
                else:
                    Print("The Hash : {LevelHash} is not founded")
            
            # Después configuramos los triggers para los siguientes niveles disponibles
            for (LevelHash : PlayerStatsTable.UnlockedLevels):
                Print("Loading trigger {LevelHash} level")
                InLevelID := IntToLevelID(LevelHash)
                if (LevelID := InLevelID?):
                    FoundLevel := Plot.FindLevelByID(LevelID)
                    if (Level := FoundLevel?):
                        for (NextLevelID : Level.UnlockAfter):
                            # Verificamos si el siguiente nivel ya está desbloqueado
                            NextLevelHash := StringToLevelID(NextLevelID)
                            checkUpgrade := hasUpgrade(Agent, NextLevelHash)
                            if (not checkUpgrade?):
                                FoundNextLevel := Plot.FindLevelByID(NextLevelID)
                                if (NextLevel := FoundNextLevel?):
                                    # Configurar trigger solo si el nivel no está desbloqueado
                                    ClaimTransform := Plot.ClaimSpace.GetTransform()
                                    NextLevel.UnlockTriggerAt(ClaimTransform)
                                    Plot.SetupTriggerForLevel(NextLevel)
                                    Print("Trigger configurado para nivel disponible: {NextLevelID}")
                    else:
                        Print("The level: {LevelID} is not founded")
                else:
                    Print("The Hash : {LevelHash} is not founded")

    # Verifica si un jugador ya tiene una parcela
    HasPlot(Agent:agent)<transacts>:logic =
        Print("Verificando parcelas del jugador")
        for (PlotIndex -> Plot : PlayerPlayspaces):
            if (PlotAgent := Plot.OwnerId?, PlotAgent = Agent):
                Print("Parcela del jugador encontrada: {PlotIndex}")
                return true
        return false

    # Player join a mutator claim zone
    OnTriggerActivated(Agent:agent, PlotIndex:int):void =
        if (Player := player[Agent]):
            Result := ClaimPlot(PlotIndex, Player)
            if (not Result.Success?):
                Print("Error al reclamar parcela: {Result.Message}")
            else:
                Print("Parcela reclamada exitosamente: {Result.Message}")

    # Cuando un jugador abandona la isla
    OnPlayerLeft(Player:player):void =
        Result := ReleasePlot(Player)
        if (not Result.Success?):
            Print("Error al liberar parcela: {Result.Message}")
        else:
            Print("Parcela liberada exitosamente: {Result.Message}")

    # Obtiene el índice de la parcela de un jugador
    GetPlayerPlotIndex(Agent:agent)<transacts>:?int =
        for (Index -> Plot : PlayerPlayspaces):
            if (PlotAgent := Plot.OwnerId?, PlotAgent = Agent):
                return option{Index}
        return false

    GetPlayerPlayspace(Agent:agent)<transacts>:?PlayerPlayspace=
        for (Index -> Plot : PlayerPlayspaces):
            if (PlotAgent := Plot.OwnerId?, PlotAgent = Agent):
                return option{Plot}
        return false