using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { /Verse.org }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }
using { /Verse.org/Assets }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Fortnite.com/Game }


horde_npc_base := class(npc_behavior):

    var Attacks: []animation_sequence = array{}

    @editable
    HordeControllerID: int = 1

    var HEC: ?HordeEventController = false

    Init()<suspends>:void=
        if (FoundHEC:= GetHordeControllerInstanceByID[HordeControllerID]?):
            set HEC = option{FoundHEC}

        if:
            NPCAgent:= GetAgent[],
            NPCChar:= NPCAgent.GetFortCharacter[],

            NPCNav:= NPCChar.GetNavigatable[],
            NPCFocus:=NPCChar.GetFocusInterface[],
            NPCAnim:= NPCChar.GetPlayAnimationController[],
            CastHEC:= HEC?
        then:
            NPCSpawnPoint := NPCChar.GetTransform().Translation

            loop:
                Sleep(0.1)

                if (not NPCChar.IsActive[]):
                    break
                
                if (NewTarget:= CastHEC.FindNearestTarget[NPCChar], NewAgent:= NewTarget.GetAgent[]):
                    spawn{NPCFocus.MaintainFocus(NewAgent)}
                    NavTarget:= MakeNavigationTarget(NewAgent)
                    
                    if:
                        CastHEC.WaveNPCstartRUN >= CastHEC.HordeCounter
                    then:
                        NPCNav.NavigateTo(NavTarget, ?MovementType:= movement_types.Walking, ?ReachRadius:= CastHEC.DamageDistance)
                    else:
                        NPCNav.NavigateTo(NavTarget, ?MovementType:= movement_types.Running, ?ReachRadius:= CastHEC.DamageDistance)

                    if (Attack:= GetRandomAttack[]?):
                        NPCAnim.Play(Attack)

                    # Damage, must fit with animation duration
                    Sleep(0.5)
                    if (Distance(NPCChar.GetTransform().Translation, NewTarget.GetTransform().Translation) < (CastHEC.DamageDistance * 2)):
                        NewTarget.Damage(CastHEC.NPCdamage)
                        
    GetRandomAttack()<decides><transacts>: ?animation_sequence=
        RandomInt:= GetRandomInt(0, Attacks.Length - 1)
        if (Attack:= Attacks[RandomInt]):
            return option{Attack}
        else:
            return false