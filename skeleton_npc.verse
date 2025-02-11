
using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Colors/NamedColors }
 
# Getting started: https://www.epicgames.com/fortnite/en-US/creative/docs/uefn/Verse/onboarding-guide-to-programming-with-verse-in-unreal-editor-for-fortnite

# A Verse-authored NPC Behavior that can be used within an NPC Character Definition or an NPC Spawner device's NPC Behavior Script Override.



skeleton_npc_behavior := class(npc_behavior):
    BehaviorHelp : BehaviorHelper = BehaviorHelper{}

    var Attack1 : animation_sequence = SkeletonNPC.SkeletonAttackAnimation
    
    NPCDamage : float = 10.0

    # This function runs when the NPC is spawned in the world and ready to follow a behavior.
    OnBegin< override>()< suspends>:void=
        # TODO: Replace this with your code
        if { 
            NPCAgent := GetAgent[]
            NPCChar := NPCAgent.GetFortCharacter[]
            
            #Allows us to tell npcs to go to different place like the pathfinding service in roblox
            NPCNav := NPCChar.GetNavigatable[]

            #Control where npc is looking
            NPCFocus := NPCChar.GetFocusInterface[]

            #Control the npc's animations
            NPCAnim := NPCChar.GetPlayAnimationController[]
        } then {
            NPCSpawnLocation := NPCChar.GetTransform().Translation

            loop {
                Sleep(0.1)
                #Checks if npc is alive
                if (not NPCChar.IsActive[]) {
                    break
                }
                if (NewTarget := BehaviorHelp.FindNearestTargetFromPos[NPCChar], NewAgent := NewTarget.GetAgent[]) {
                    spawn{NPCFocus.MaintainFocus(NewAgent)}
                    NavTarget := MakeNavigationTarget(NewAgent)
                    NPCNav.NavigateTo(NavTarget, ?MovementType := movement_types.Running, ?ReachRadius := 150.0)
                    NPCAnim.Play(Attack1)
                    Sleep(0.58)

                    DistanceDifference := Distance(NPCChar.GetTransform().Translation, NewTarget.GetTransform().Translation)

                    if (DistanceDifference < 200.0) {
                        NewTarget.Damage(NPCDamage)
                    }
                } 
            }
        }

    # This function runs when the NPC is despawned or eliminated from the world.
    OnEnd< override>():void=
        # TODO: Replace this with your code
        Print("Goodbye, NPC!")


using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
BehaviorHelper := class(creative_device):
    
    FindNearestTargetFromPos(FortChar : fort_character)< decides>< transacts> : fort_character = {
        var MaybeTarget : ?fort_character = false

        #Change this range how you would like
        #This will be the range that the device will search for the nearest target
        var CheckRange : float = 5000.0

        for (Player : GetPlayspace().GetPlayers(), PlayerFortChar := Player.GetFortCharacter[]) {
            DistanceDifference := Distance(FortChar.GetTransform().Translation, PlayerFortChar.GetTransform().Translation)

            if (DistanceDifference < CheckRange and not PlayerFortChar = FortChar) {
                set MaybeTarget = option{PlayerFortChar}
                set CheckRange = DistanceDifference 
            }
        }

        return MaybeTarget?
    }

    # Runs when the device is started in a running game
    OnBegin< override>()< suspends>:void=
        # TODO: Replace this with your code
        Print("Hello, world!")