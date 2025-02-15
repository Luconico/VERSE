using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices/CreativeAnimation }

interpolation_type := enum{Linear, Ease, EaseIn, EaseOut, EaseInOut}

dropper_reward := class<concrete>():
    @editable
    CurrencyID : string = "Money"

    @editable
    Amount : int = 1

relative_point := class<concrete>:
    @editable
    PropReference : creative_prop = creative_prop{}
    
    @editable
    Rotation : rotation = rotation{}

    @editable
    Scale : vector3 = vector3{X := 1.0, Y := 1.0, Z := 1.0}

    @editable
    Interpolation : interpolation_type = interpolation_type.Linear

    @editable
    Duration : float = 1.0

    @editable
    PauseDuration : float = 0.0

dropper_item := class<concrete>:
    @editable
    InitialPropReference : creative_prop = creative_prop{}

    @editable
    ItemProp : creative_prop_asset = DefaultCreativePropAsset

    @editable
    MovementPoints : []relative_point = array{}

    @editable 
    SpawnInterval : float = 2.0  # Time between item spawns

    @editable
    ItemDuration : float = 5.0   # How long each item exists

    @editable
    Reward : dropper_reward = dropper_reward{}

    @editable
    StartOnBegin : logic = true

    var DropperKeyframes : []keyframe_delta = array{}
    var ActiveProps : []creative_prop = array{}
    var IsActive : logic = false

dropper_device := class():
    @editable
    Dropper : dropper_item = dropper_item{}

    # Reference to currency manager
    var CurrenciesManager : ?CurrencyManager = false
    var OwnerID: ?agent = false

    InitializeDropper():void =
        Print("Initializing dropper system...")
        set Dropper.DropperKeyframes = GetAnimationKeys(Dropper.MovementPoints)
        if (Dropper.StartOnBegin?):
            ActivateDropper()
    
    InitializePOwnerID(Agent : ?agent):void =
        set OwnerID = Agent

    SetCurrencyManager(Manager : CurrencyManager):void =
        set CurrenciesManager = option{Manager}

    ActivateDropper():void =
        if (not Dropper.IsActive?):
            set Dropper.IsActive = true
            spawn { RunDropperGenerator() }

    DeactivateDropper():void =
        set Dropper.IsActive = false

    RunDropperGenerator()<suspends>:void =
        loop:
            if (not Dropper.IsActive?):
                break
            spawn{RunDropperLoop()}
            Sleep(Dropper.SpawnInterval)

    RunDropperLoop()<suspends>:void =
        if (Manager := CurrenciesManager?):
            # Check if we can spawn based on active props
            MaybeNewItem := SpawnItem()
            if (NewItem := MaybeNewItem?):

                if (Controller := NewItem.GetAnimationController[]):
                    Controller.SetAnimation(Dropper.DropperKeyframes, ?Mode := animation_mode.OneShot)
                    Controller.Play()

                    # Wait for animation
                    Sleep(Dropper.ItemDuration)

                    # Remove and dispose
                    # Get players in range and distribute rewards
                    # for (Player : Manager.GetPlayspace().GetPlayers()):
                    #     if (Agent := agent[Player]):
                    #         Manager.AddCurrency(Agent, Dropper.Reward.CurrencyID, Dropper.Reward.Amount)

                    if (Owner:= OwnerID?):
                        Manager.AddCurrency(Owner, Dropper.Reward.CurrencyID, Dropper.Reward.Amount)

                    NewItem.Dispose()
                    
    GetAnimationKeys(Points : []relative_point):[]keyframe_delta =
        # Calculate absolute positions
        var Keys : []keyframe_delta = array{}

        var InitialPointTranslation: vector3 = GetTranslationFromCreativeProp(Dropper.InitialPropReference)

        for (Index -> Point : Points):
            Print("Loading frame #{Index}")
            
            KeyFrameTranslation := GetTranslationFromCreativeProp(Point.PropReference)

            # Calculate diff between initial and target
            CalculatedTranslation: vector3 = vector3{
                X := KeyFrameTranslation.X - InitialPointTranslation.X,
                Y := KeyFrameTranslation.Y - InitialPointTranslation.Y,
                Z := KeyFrameTranslation.Z - InitialPointTranslation.Z
            }

            set InitialPointTranslation = KeyFrameTranslation
    
            var DeltaLoc : vector3 = CalculatedTranslation
            var DeltaRot : rotation = Point.Rotation
            
            Print("- Delta Location: {DeltaLoc}")
            Print("- Delta Rotation: {DeltaRot}")
            set Keys += array{keyframe_delta{
                DeltaLocation := CalculatedTranslation
                DeltaRotation := Point.Rotation
                DeltaScale := Point.Scale
                Time := Point.Duration
                Interpolation := InterpolationTypes.Linear
            }}

        Print("Generated {Keys.Length} keyframes for animation")
        return Keys

    SpawnItem():?creative_prop =
        InitialTranslation:= GetTranslationFromCreativeProp(Dropper.InitialPropReference)
        Print("Spawning item at {InitialTranslation}")
        ItemResult := SpawnProp(Dropper.ItemProp, InitialTranslation, rotation{})
        if (ItemResult(1) = spawn_prop_result.Ok):
            return ItemResult(0)
        
        return false

    GetTranslationFromCreativeProp(Prop : creative_prop):vector3 =
        return Prop.GetTransform().Translation