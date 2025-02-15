
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

pets_controller:= class<concrete>:

    @editable
    PetTrigger : trigger_device = trigger_device{}

    @editable
    UnlockPrice : int = 0

    @editable
    NPCSpawner : npc_spawner_device = npc_spawner_device{}

    var PetsHelper : pets_helper_device = pets_helper_device{}

    # Map to store the player's pet owner
    var PlayersOwners : [agent]agent = map {}

    Init(_PH: pets_helper_device):void=
        set PetsHelper = _PH

    OnPetTriggered(Agent: ?agent):void=
        # Check if the agent is a player
        if (CastAgent:= Agent?):
            Print("Pet triggered, unlock price {UnlockPrice}")

            # Check if the player already owns the pet and finish the function
            var playerIsOwner: logic = PlayerIsOwner(CastAgent)
            if (playerIsOwner?):
                NPCSpawner.Spawn()
                Print("Player is owner")
                return

            Bought := PetsHelper.CurrenciesManager.CheckAndRemoveCurrency(CastAgent, "Money", UnlockPrice)

            if (Bought?):
                Print("Pet bought")
                # save the player as owner
                if (set PlayersOwners[CastAgent] = CastAgent) {}

                if (SetPlayerPetTarget(CastAgent.GetFortCharacter[])) {}
                NPCSpawner.Spawn()

                PetsHelper.EXPgetOnePet.Award(CastAgent)
                IsOwnerOfAllPets:= PlayerOwnAllPets(CastAgent)
                if (IsOwnerOfAllPets?):
                    PetsHelper.EXPgetAllPet.Award(CastAgent)
            else:
                Print("Not enough money")
                PetsHelper.HUBdevice.Show(CastAgent)


    PlayerIsOwner(Agent: agent):logic=
        var result: logic = false
        for (PlayerOwner: PlayersOwners):
            if (PlayerOwner = Agent):
                set result = true
        
        return result

    PlayerOwnAllPets(Agent: agent):logic=
        var result: logic = true
        for (PetController: PetsHelper.PetControllers):
            IsOwner:= PetController.PlayerIsOwner(Agent)
            if (not IsOwner?):
                set result = false
        
        return result


# A Verse-authored creative device that can be placed in a level
pets_helper_device := class(creative_device):

    @editable
    PetControllers : []pets_controller = array{}

    @editable
    CurrenciesManager : CurrencyManager = CurrencyManager{}

    @editable
    HUBdevice : hud_message_device = hud_message_device{}

    # Global map to store the player's pet target
    var Owners: [fort_character]fort_character = map{}

    @editable
    EXPgetOnePet:accolades_device = accolades_device{}

    @editable
    EXPgetAllPet:accolades_device = accolades_device{}

    OnBegin<override>()<suspends>:void=
        for (PetController : PetControllers):
            PetController.PetTrigger.TriggeredEvent.Subscribe(PetController.OnPetTriggered)
            PetController.NPCSpawner.SpawnedEvent.Subscribe(OnNPCspawned)
            PetController.Init(Self)
        
        EXPgetOnePet.Enable()
        EXPgetOnePet.TestAwardEvent.Subscribe(OnTestAward)
        EXPgetAllPet.TestAwardEvent.Subscribe(OnTestAward)
    
    OnTestAward(Agent: agent):void=
        Print("Test award")
    
    OnNPCspawned(NPC: agent):void=
        if (NPCChar:= NPC.GetFortCharacter[]):
            if (CurrentPet:= Owners[GetPlayerPetTarget[]]):
                CurrentPet.SetVulnerability(true)
                CurrentPet.Damage(1000.0)

            if (set Owners[GetPlayerPetTarget[]] = NPCChar):
                Print("Pet spawned and assigned to player")
            
# Global map to store the player's pet target
var PlayerPetTarget : weak_map(session, fort_character) = map{}

SetPlayerPetTarget<public>( Target : fort_character)<transacts>: void =
    if (set PlayerPetTarget[GetSession()] = Target) {}

GetPlayerPetTarget<public>()<decides><transacts>: fort_character =
    var Target : ?fort_character = false
    if (FindTarget := PlayerPetTarget[GetSession()]):
        set Target = option{FindTarget}
    return Target?