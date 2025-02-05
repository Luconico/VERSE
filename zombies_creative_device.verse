
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Game }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
zombies_creative_device := class(creative_device):

  @editable
  ZombieDamage: float = 100.0

  var CLD: custom_leaderboard_device = custom_leaderboard_device {}

  FindNearestTarget(FC : fort_character)<decides><transacts>: fort_character =
    var MaybeTarget : ?fort_character = false
    var CheckRange : float = 5000.0

    for (Player: GetPlayspace().GetPlayers(), PlayerFC:= Player.GetFortCharacter[]):
        if:
            DistaceDiference:= Distance(PlayerFC.GetTransform().Translation, FC.GetTransform().Translation) < CheckRange
            not PlayerFC = FC
        then:
            set MaybeTarget = option{PlayerFC}
            set CheckRange = DistaceDiference

    return MaybeTarget?

  GetZombieDamage()<transacts>: float =
    return ZombieDamage

  OnZombieDied(EliminationResult : elimination_result):void=
    CLD.OnNPCEliminated(EliminationResult)