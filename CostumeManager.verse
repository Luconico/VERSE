
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

CostumeItemController := class():

    @editable
    PurchaseTrigger : trigger_device = trigger_device{}

    @editable
    CostumeItem : visual_effect_powerup_device = visual_effect_powerup_device {}

    @editable
    UnlockPrice : int = 0

    @editable
    CurrencyType: CurrenciesTextures = CurrenciesTextures.Hearts

    var CurrenciesManager: CurrencyManager = CurrencyManager{}

    var Owners: [agent]agent = map{}

    Init(_CM: CurrencyManager):void=
        set CurrenciesManager = _CM

    OnCostumeItemTriggered(Agent: ?agent):void=
        if (CastAgent:= Agent?):

            IsOwner := PlayerIsOwner(CastAgent)
            if (IsOwner?):
                Print("Player is owner")
                CostumeItem.Pickup(CastAgent)
                return

            Bought := CurrenciesManager.CheckAndRemoveCurrency(CastAgent, CurrencyToString(CurrencyType), UnlockPrice)

            if (Bought?):
                CostumeItem.Pickup(CastAgent)
                if (set Owners[CastAgent] = CastAgent) {}
            else:
                Print("Not enough money")
    
    PlayerIsOwner(Agent: agent):logic=
        var result: logic = false
        for (PlayerOwner: Owners):
            if (PlayerOwner = Agent):
                set result = true
        
        return result

         
    

# A Verse-authored creative device that can be placed in a level
CostumeManager := class(creative_device):

    @editable
    CurrenciesManager : CurrencyManager = CurrencyManager{}

    @editable
    CostumeItemControllers : []CostumeItemController = array{}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        for (ItemController : CostumeItemControllers):
            ItemController.Init(CurrenciesManager)
            ItemController.PurchaseTrigger.TriggeredEvent.Subscribe(ItemController.OnCostumeItemTriggered)