
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
    var CostumesManager: CostumeManager = CostumeManager{}

    var Owners: [agent]agent = map{}

    Init(_CM: CurrencyManager, _CostumeM: CostumeManager):void=
        set CurrenciesManager = _CM
        set CostumesManager = _CostumeM

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
                
                CostumesManager.EXPgetOneCostume.Award(CastAgent)
                IsOwnerOfAllCostumes:= PlayerOwnAllCostumes(CastAgent)
                if (IsOwnerOfAllCostumes?):
                    CostumesManager.EXPgetAllCostume.Award(CastAgent)
            else:
                Print("Not enough money")
                CostumesManager.HUBdevice.Show(CastAgent)
    
    PlayerIsOwner(Agent: agent):logic=
        var result: logic = false
        for (PlayerOwner: Owners):
            if (PlayerOwner = Agent):
                set result = true
        
        return result

    PlayerOwnAllCostumes(Agent: agent):logic=
        var result: logic = true
        for (Controller: CostumesManager.CostumeItemControllers):
            IsOwner:= Controller.PlayerIsOwner(Agent)
                if (not IsOwner?):
                    set result = false

        return result

    

# A Verse-authored creative device that can be placed in a level
CostumeManager := class(creative_device):

    @editable
    CurrenciesManager : CurrencyManager = CurrencyManager{}

    @editable
    CostumeItemControllers : []CostumeItemController = array{}

    @editable
    EXPgetOneCostume:accolades_device = accolades_device{}

    @editable
    EXPgetAllCostume:accolades_device = accolades_device{}

    @editable
    HUBdevice : hud_message_device = hud_message_device{}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        for (ItemController : CostumeItemControllers):
            ItemController.Init(CurrenciesManager, Self)
            ItemController.PurchaseTrigger.TriggeredEvent.Subscribe(ItemController.OnCostumeItemTriggered)

        EXPgetOneCostume.TestAwardEvent.Subscribe(OnTestAward)
        EXPgetAllCostume.TestAwardEvent.Subscribe(OnTestAward)

    OnTestAward(Agent: agent):void=
        Print("Test award")