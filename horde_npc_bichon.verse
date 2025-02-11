using { /Verse.org/Assets }

horde_npc_bichon := class(horde_npc_base):

    var Attack1: animation_sequence = assets.Abichonuevo.bichon30.bichonv1_Anim

    OnBegin<override>()<suspends>:void=
        set Attacks = array{Attack1}
        Init()