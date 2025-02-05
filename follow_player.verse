using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
 
device_reference := class(tag){}
 
my_creative_device := class(creative_device):
 
    @editable
    var PlayerSpawner : player_spawner_device = player_spawner_device {}
 
    @editable
    var NPCSpawner : npc_spawner_device = npc_spawner_device {}
 
    var LastPlayerSpawned: ?agent = false
    var LastNPCSpawned: ?agent = false
 
    #Pairing spawned NPCs to spawned players. Both players and AI are of agent type. 
    var NPCPlayerMapping : [agent]agent = map {}
 
 
    OnBegin<override>()<suspends>:void=
        PlayerSpawner.SpawnedEvent.Subscribe(OnPlayerSpawn)
        NPCSpawner.SpawnedEvent.Subscribe(OnNPCSpawn)
        
        loop:
            if (NPCAgent := LastNPCSpawned?):
                FollowPlayer(NPCAgent)
            Sleep(0.0)
 
    # When player spawns, this links the NPC reference (the KEY) to the Player reference (the Value).
    OnNPCSpawn(NPCAgent : agent) : void =
        if(FortCharacter := NPCAgent.GetFortCharacter[]):
            set LastNPCSpawned = option{NPCAgent}

        if (PlayerAgent := LastPlayerSpawned?):
            if(set NPCPlayerMapping[NPCAgent] = PlayerAgent){}

    FollowPlayer(NPCAgent: agent)<suspends>:void=
        if:
            Character:= NPCAgent.GetFortCharacter[],
            Navigatable := Character.GetNavigatable[]
        then:
            if (AgentTarget := LastPlayerSpawned?):
                NavTarget := MakeNavigationTarget(AgentTarget),
                Navigatable.NavigateTo(NavTarget)
        Sleep(0.0)

    # This method is called with a reference to the NPC, and returns a reference to the Player.
    # You need the KEY to get access to the VALUE.
    # GetNPCFollowTarget( NPCAgent : agent )<transacts> : ?agent =
    #     var FollowAgent: ?agent = false
    #     if (FoundAgent := NPCPlayerMapping[NPCAgent]):
    #         set FollowAgent = option{FoundAgent}
    #     else:
    #         set FollowAgent = LastPlayerSpawned
    #     return FollowAgent
 
    #Teleport NPC to Player spawn location.
    OnPlayerSpawn(Agent: agent): void =
        if(FortCharacter := Agent.GetFortCharacter[]):
            set LastPlayerSpawned = option{Agent}
            #set LastPlayerSpawned = option{Agent}
           #if(NPCSpawner.TeleportTo[FortCharacter.GetTransform().Translation, rotation{}]):
                #NPCSpawner.Spawn()