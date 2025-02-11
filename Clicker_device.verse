using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/Devices/CreativeAnimation/InterpolationTypes }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }

clicker_prop_device := class(creative_device):

    @editable
    PropManipulator : prop_manipulator_device = prop_manipulator_device{}

    @editable
    ClickerProp : creative_prop = creative_prop{}

    @editable
    Manager : ?TycoonManager = false

    var AnimationKeyFrames : []keyframe_delta = array{}

    Notification : PopupNotification = PopupNotification{}

    OnBegin<override>()<suspends>:void=
        Print("OnBegin")

        PropManipulator.DamagedEvent.Subscribe(OnPropDamaged)

        TargetScale : float = 0.8
        InverseTargetScale : float = 1.0/0.8
        DownScaleKeyFrame : keyframe_delta = keyframe_delta
        {
            DeltaLocation := vector3{ X := 0.0, Y := 0.0, Z := 0.0 }
            DeltaRotation := IdentityRotation()
            DeltaScale := vector3{ X := TargetScale, Y := TargetScale, Z := TargetScale }
            Time := 0.2
            Interpolation := EaseIn
        }

        UpScaleKeyFrame : keyframe_delta = keyframe_delta
        {
            DeltaLocation := vector3{ X := 0.0, Y := 0.0, Z := 0.0 }
            DeltaRotation := IdentityRotation()
            DeltaScale := vector3{ X := InverseTargetScale, Y := InverseTargetScale, Z := InverseTargetScale }
            Time := 0.2
            Interpolation := EaseIn
        }

        set AnimationKeyFrames = array{ DownScaleKeyFrame, UpScaleKeyFrame }

    OnPropDamaged(Agent : agent):void=
        
        if (MainManager := Manager?):
            var playerUnlocks: float = ((1.0 * getUnlockedLevelsNumber(Agent)) / 10.0) + 1.0
            var toAdd: int = 10

            if (TempToAdd:= Round[10.0 * playerUnlocks]):
                set toAdd = TempToAdd

            MainManager.CurrenciesManager.AddCurrency(Agent, "Money", toAdd)
            Notification.ShowNotification(Agent, toAdd, material_type.Money)
            Print("anado {toAdd} moneda al jugador")
        else:
            Print("Manager no asignado; no se pudo agregar dinero al jugador.")


        if (PropAnimController := ClickerProp.GetAnimationController[]):
            AnimState := PropAnimController.GetState()
            if (AnimState = animation_controller_state.AnimationNotSet or AnimState = animation_controller_state.Stopped):
                PropAnimController.SetAnimation(AnimationKeyFrames, ?Mode := animation_mode.OneShot)
                PropAnimController.Play()