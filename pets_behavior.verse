using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Game }

# A Verse-authored NPC Behavior that can be used within an NPC Character Definition or an NPC Spawner device's NPC Behavior Script Override.
pets_behavior := class(npc_behavior):

    # This function runs when the NPC is spawned in the world and ready to follow a behavior.
    OnBegin<override>()<suspends>:void=
        if: 
            NPCAgent:= GetAgent[],
            NPCChar:= NPCAgent.GetFortCharacter[],
            NPCNav:= NPCChar.GetNavigatable[],
            NPCFocus:=NPCChar.GetFocusInterface[]
        then:
            NPCSpawnPoint := NPCChar.GetTransform().Translation
            Sleep(1.0)
            # Loop for handle pets behavior
            if (NewTarget:= GetPlayerPetTarget[], NewAgent:= NewTarget.GetAgent[]):
                Print("NewAgent")
                loop:
                    Sleep(0.1)
                    if (not NPCChar.IsActive[]):
                        break
                
                    spawn{NPCFocus.MaintainFocus(NewAgent)}
                    NavTarget:= MakeNavigationTarget(NewAgent)
                    NavResultGoTo:= NPCNav.NavigateTo(NavTarget, ?MovementType:= movement_types.Running, ?ReachRadius:= 150.0)

                    if (NavResultGoTo <> navigation_result.Reached):
                        if (NPCChar.TeleportTo[NewTarget.GetTransform().Translation, MakeRotationFromYawPitchRollDegrees(0.0, 0.0, 0.0)]) {}
