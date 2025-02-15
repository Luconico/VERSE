using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Game }
# Getting started: https://www.epicgames.com/fortnite/en-US/creative/docs/uefn/Verse/onboarding-guide-to-programming-with-verse-in-unreal-editor-for-fortnite

Assetstimport<public> := module: #adding <public> specifier
    baCKROOM<public> := module{} #adding <public> specifier

# A Verse-authored NPC Behavior that can be used within an NPC Character Definition or an NPC Spawner device's NPC Behavior Script Override.
zombies_behavior := class(npc_behavior):

    ZCD: zombies_creative_device = zombies_creative_device {}
    var Attack1: animation_sequence = Assetstimport.baCKROOM.Zombie_Skill

    # This function runs when the NPC is spawned in the world and ready to follow a behavior.
    OnBegin<override>()<suspends>:void=
        if:
            NPCAgent:= GetAgent[],
            NPCChar:= NPCAgent.GetFortCharacter[],

            NPCNav:= NPCChar.GetNavigatable[],
            NPCFocus:=NPCChar.GetFocusInterface[],
            NPCAnim:= NPCChar.GetPlayAnimationController[]
        then:
            NPCSpawnPoint := NPCChar.GetTransform().Translation

            # Subscribe to the NPC's EliminatedEvent to know when the NPC is eliminated.
            NPCChar.EliminatedEvent().Subscribe(ZCD.OnZombieDied)

            # Loop for handle zombie behavior
            loop:
                Sleep(0.1)

                if (not NPCChar.IsActive[]):
                    break

                if (NewTarget:= ZCD.FindNearestTarget[NPCChar], NewAgent:= NewTarget.GetAgent[]):
                    spawn{NPCFocus.MaintainFocus(NewAgent)}
                    NavTarget:= MakeNavigationTarget(NewAgent)
                    NPCNav.NavigateTo(NavTarget, ?MovementType:= movement_types.Walking, ?ReachRadius:= 200.0)

                    NPCAnim.Play(Attack1)

                    # Damage, must fit with animation duration
                    Sleep(1.5)
                    if (Distance(NPCChar.GetTransform().Translation, NewTarget.GetTransform().Translation) < 300.0):
                        NewTarget.Damage(ZCD.GetZombieDamage())