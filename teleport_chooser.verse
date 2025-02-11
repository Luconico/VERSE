
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

teleport_type := enum {
    Random,
    Deterministic
}

# A Verse-authored creative device that can be placed in a level
teleport_chooser := class(creative_device):

    @editable
    MutationZone : mutator_zone_device = mutator_zone_device {}

    @editable
    TPdevices : []teleporter_device = array{}

    @editable
    TPtype : teleport_type = teleport_type.Random

    var LastDevice : int = 0

    OnBegin<override>()<suspends>:void=
        MutationZone.AgentEntersEvent.Subscribe(OnAgentEnters)
    
    OnAgentEnters(Agent : agent) : void =
        if:
            TPtype = teleport_type.Random
        then:
            if (TPdevice := GetRandomTPdevice[]):
                TPdevice.Teleport(Agent)
        if:
            TPtype = teleport_type.Deterministic
        then:
            if (TPdevice := GetTPdevice[]):
                TPdevice.Teleport(Agent)
    
    GetRandomTPdevice()<decides><transacts>:teleporter_device =
        var RandomIndex : int = GetRandomInt(0, TPdevices.Length - 1)
        return TPdevices[RandomIndex]

    GetTPdevice()<decides><transacts>:teleporter_device =
        var DeviceToReturn: int = LastDevice

        if:
            LastDevice = TPdevices.Length - 1
        then:
                set LastDevice = 0
        else:
                set LastDevice = LastDevice + 1

        return TPdevices[DeviceToReturn]