using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }

user_interface<public> := module:

    # 'z_order' is a public type that represents an integer value '_X', constrained to be between 0 and 2147483647, used to define UI
    z_order<public> := type { _X : int where 0 <= _X, _X <= 2147483647 }

    widget_interface<public> := interface:

        # Adds an interactive UI element to the widget, with an optional Z-order parameter to control layering.
        AddInteractUI<public>(?ZOrder : z_order = 0) : void

        # Adds a gameplay-related UI element to the widget, also with an optional Z-order parameter for layering.
        AddGameplayUI<public>(?ZOrder : z_order = 0) : void
        
        # Removes the UI element from the widget, clearing it from the interface.
        RemoveUI<public>() : void

    # 'widget_base' is an abstract class that implements the 'widget_interface'.
    widget_base<public> := class<abstract>(widget_interface):
        
        # Represents the associated player object.
        Player<public> : player
        
        # Optional canvas variable, initialized to 'false' (or null).
        var MaybeCanvas<private> : ?canvas = false

        # Creates and returns a canvas object.
        CreateCanvas<protected>() : canvas

        InterfaceDisplayedEvent<protected>() : void = {}
        InterfaceDissapearEvent<protected>() : void = {}

        AddUI<internal><final>(InterfaceSlot : player_ui_slot) : void =
            if:
                Player.IsActive[]
                PlayerUI : player_ui = GetPlayerUI[Player]
            then:
                Canvas : canvas = CreateCanvas()

                PlayerUI.AddWidget(Canvas, InterfaceSlot)
                set MaybeCanvas = option{ Canvas }
    
                InterfaceDisplayedEvent()

        AddInteractUI<override><final>(?ZOrder : z_order = 0) : void =
            AddUI(
                player_ui_slot{ 
                    ZOrder := ZOrder
                    InputMode := ui_input_mode.All
                }
            )

        AddGameplayUI<override><final>(?ZOrder : z_order = 0) : void =
            AddUI(
                player_ui_slot{ 
                    ZOrder := ZOrder
                    InputMode := ui_input_mode.None
                }
            )

        RemoveUI<override><final>() : void =
            if:
                Player.IsActive[]
                PlayerUI : player_ui = GetPlayerUI[Player]
                Canvas : canvas = MaybeCanvas?
            then:
                PlayerUI.RemoveWidget(Canvas)
                set MaybeCanvas = false

                InterfaceDissapearEvent()