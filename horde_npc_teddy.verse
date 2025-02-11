using { /Verse.org/Assets }

horde_npc_teddy := class(horde_npc_base):

    var Attack1: animation_sequence = assets.AAoso.OSO500.oaoMOEOAO_Anim_Armature_Armature_Armature_push
    var Attack2: animation_sequence = assets.AAoso.OSO500.oaoMOEOAO_Anim_Armature_Armature_Armature_kick

    OnBegin<override>()<suspends>:void=
        set Attacks = array{Attack1, Attack2}
        Init()