
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
    NPCSpawner : npc_spawner_device = npc_spawner_device {}

    OnPetTriggered(Agent: ?agent):void=
        Print("Pet triggered, unlock price {UnlockPrice}")


# A Verse-authored creative device that can be placed in a level
pets_helper_device := class(creative_device):

    @editable
    PetControllers : []pets_controller = array{}

    @editable
    CurrenciesManager : CurrencyManager = CurrencyManager{}

    var CurrentTarget : ?fort_character = false

    # GetCurrentPlayerTarget()<decides><transacts>: fort_character =
    #     return CurrentTarget?

    # SetCurrentPlayerTarget(NewTarget : fort_character)<transacts>:void=
    #     set CurrentTarget = option{NewTarget}

    OnBegin<override>()<suspends>:void=
        for (PetController : PetControllers):
            PetController.PetTrigger.TriggeredEvent.Subscribe(PetController.OnPetTriggered)
            
  
