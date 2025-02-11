using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/UI }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { Utils }

material_type := enum:
    Money
    EXP
    Hearts

# Struct para manejar notificaciones acumuladas
accumulated_notification_data := class:
    ID : string = ""
    MaterialType : material_type 
    var TotalValue : int = 0
    var LastUpdateTime : float = 0.0
    var WidgetInstance : widget
    var Canvas : canvas
    var TextBlock : text_block
    var Position : vector2 = vector2{X := 0.0, Y := 0.0}

# Struct to hold notification data
notification_data := class:
    ID : string = ""
    Value : int = 0
    var Position : vector2 = vector2{X := 0.0, Y := 0.0}
    StartTime : float = 0.0
    var Widget : widget
    var Canvas : canvas
    var Text : text_block
    MatType : material_type
    InitialX : float = 0.0  # Store initial X position

PopupNotification := class:
    # Time each notification stays visible
    Duration : float = 1.0
    
    # Animation parameters for subtle side motion
    SideMotionAmount : float = 0.01  # How far it moves to the sides
    MotionSpeed : float = 4.0         # How fast it completes one side-to-side cycle
    
    # Vertical movement speed
    VerticalSpeed : float = 0.006
    
    # Current active notifications
    var ActiveNotifications : []notification_data = array{}

    # Notificaciones acumuladas activas
    var AccumulatedNotifications : [material_type]accumulated_notification_data = map{}

    # Cola de notificaciones pendientes
    var NotificationQueue : []tuple(int, material_type) = array{}
    var IsProcessingQueue : logic = false

    # Constantes para el espaciado de notificaciones acumulativas
    BaseAccumulatedY : float = 0.5  # Posición Y inicial
    AccumulatedYSpacing : float = 0.04  # Aumentado para mejor separación

    # Muestra una notificación
    ShowNotification(Agent : agent, Value : int, MaterialType : material_type):void =
        # Añadir a la cola
        set NotificationQueue += array{(Value, MaterialType)}
        
        # Si no hay proceso de cola activo, iniciarlo
        if (not IsProcessingQueue?):
            set IsProcessingQueue = true
            spawn{ProcessNotificationQueue(Agent)}

    # Procesa la cola de notificaciones
    ProcessNotificationQueue(Agent : agent)<suspends>:void =
        loop:
            if (NotificationQueue.Length > 0):
                if (FirstNotification := NotificationQueue[0]):
                    Value := FirstNotification(0)
                    MaterialType := FirstNotification(1)
                    
                    # Mostrar la notificación actual
                    ShowNotificationImmediate(Agent, Value, MaterialType)
                    
                    # Remover la notificación procesada de la cola
                    if (NotificationQueue.Length > 1):
                        if (NewQueue := NotificationQueue.Slice[1, NotificationQueue.Length]):
                            set NotificationQueue = NewQueue
                    else:
                        set NotificationQueue = array{}

                    # Esperar antes de mostrar la siguiente
                    Sleep(0.3)  # Ajusta este valor según necesites
            else:
                set IsProcessingQueue = false
                break

    # Muestra una notificación inmediatamente (versión interna)
    ShowNotificationImmediate(Agent : agent, Value : int, MaterialType : material_type):void =
        if (PlayerUI := GetPlayerUI[player[Agent]]):
            # Gestionar notificación acumulada
            HandleAccumulatedNotification(Agent, Value, MaterialType)

            # Crear notificación normal
            var AdjustedPosition : vector2 = vector2{ X := 0.6, Y := 0.5}
            set AdjustedPosition.X += GetRandomFloat(-0.02, 0.02)
            
            MaybeNotification := CreateNotification(Value, AdjustedPosition, MaterialType)
            if (Notification := MaybeNotification?):
                ID := "{GetSimulationElapsedTime()}"

                NewNotification := notification_data:
                    ID := ID
                    Value := Value
                    Position := AdjustedPosition
                    StartTime := GetSimulationElapsedTime()
                    Widget := Notification(2)
                    Canvas := Notification(0)
                    Text := Notification(1)
                    MatType := MaterialType
                    InitialX := AdjustedPosition.X
                
                PlayerUI.AddWidget(Notification(0))
                set ActiveNotifications += array{NewNotification}
                spawn{AnimateNotification(Agent, NewNotification)}

    # Maneja la lógica de notificaciones acumuladas
    HandleAccumulatedNotification(Agent : agent, Value : int, MaterialType : material_type):void =
        if (ExistingAccumulated := AccumulatedNotifications[MaterialType]):
            # Actualizar notificación existente
            UpdateExistingAccumulation(Agent, ExistingAccumulated, Value)
        else:
            # Crear nueva notificación acumulada
            CreateNewAccumulation(Agent, Value, MaterialType)

    # Actualiza una notificación acumulada existente
    UpdateExistingAccumulation(Agent : agent, Notification : accumulated_notification_data, Value : int):void =
        set Notification.TotalValue += Value
        set Notification.LastUpdateTime = GetSimulationElapsedTime()
        UpdateAccumulatedDisplay(Agent, Notification)

    # Crea una nueva notificación acumulada
    CreateNewAccumulation(Agent : agent, Value : int, MaterialType : material_type):void =
        if (PlayerUI := GetPlayerUI[player[Agent]]):
            NewAccumulated := CreateAccumulatedWidget(Value, MaterialType)
            if (set AccumulatedNotifications[MaterialType] = NewAccumulated):
                PlayerUI.AddWidget(NewAccumulated.Canvas)
                UpdateAccumulatedPositions()
                spawn{MonitorAccumulatedTimeout(Agent, MaterialType)}

    # Crea el widget para notificación acumulada
    CreateAccumulatedWidget(Value : int, MaterialType : material_type):accumulated_notification_data =
        TextBlockInstance := text_block:
            DefaultText := StringToMessage(" x {FormatCurrency(Value)}")
            DefaultTextColor := NamedColors.White
            DefaultShadowColor := NamedColors.Black
            DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}
            DefaultTextOpacity := 1.0
            DefaultShadowOpacity := 0.5

        MaterialIcon := texture_block:
            DefaultImage := GetTextureFromMaterial(MaterialType)
            DefaultDesiredSize := vector2{X := 32.0, Y := 32.0}

        ContainerBox := overlay:
            Slots := array:
                overlay_slot:
                    Widget := color_block{DefaultColor := NamedColors.Black, DefaultOpacity := 0.5}
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                overlay_slot:
                    Widget := stack_box:
                        Orientation := orientation.Horizontal
                        Slots := array{
                            stack_box_slot{
                                Widget := MaterialIcon
                                HorizontalAlignment := horizontal_alignment.Center
                                Padding := margin{ Left := 5.0, Right := 5.0}
                            },
                            stack_box_slot{
                                Widget := TextBlockInstance
                                HorizontalAlignment := horizontal_alignment.Fill
                                Padding := margin{ Right := 5.0}
                            }
                        }

        InitialY := BaseAccumulatedY + ((AccumulatedNotifications.Length - 1) * AccumulatedYSpacing)
        AccumulatedCanvas := canvas:
            Slots := array{
                canvas_slot{
                    Anchors := anchors{
                        Minimum := vector2{X := 0.6, Y := InitialY}
                        Maximum := vector2{X := 0.6, Y := InitialY}
                    }
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                    Widget := ContainerBox
                }
            }

        return accumulated_notification_data:
            MaterialType := MaterialType
            TotalValue := Value
            LastUpdateTime := GetSimulationElapsedTime()
            WidgetInstance := ContainerBox
            Canvas := AccumulatedCanvas
            TextBlock := TextBlockInstance

    # Actualiza el display de una notificación acumulada
    UpdateAccumulatedDisplay(Agent : agent, Notification : accumulated_notification_data):void =
        Notification.TextBlock.SetText(StringToMessage(" x {FormatCurrency(Notification.TotalValue)}"))

    # Monitor para timeout de notificaciones acumuladas
    MonitorAccumulatedTimeout(Agent : agent, MaterialType : material_type)<suspends>:void =
        loop:
            Sleep(0.1)
            if (Notification := AccumulatedNotifications[MaterialType]):
                CurrentTime := GetSimulationElapsedTime()
                if (CurrentTime - Notification.LastUpdateTime >= 3.0):
                    if (PlayerUI := GetPlayerUI[player[Agent]]):
                        PlayerUI.RemoveWidget(Notification.Canvas)
                        RemoveElementFromMap(MaterialType) # Removemos el elemento del mapa
                        break
    
    # Reposiciona las notificaciones acumulativas
    UpdateAccumulatedPositions():void =
        var CurrentY : float = BaseAccumulatedY
        var OrderedMaterials : []material_type = array{}

        # Recolectar y ordenar los materiales activos
        for (MaterialType -> NoUse : AccumulatedNotifications):
            set OrderedMaterials = OrderedMaterials + array{MaterialType}

        # Actualizar posición para cada notificación acumulada
        for (MaterialType : OrderedMaterials):
            if (Notification := AccumulatedNotifications[MaterialType]):
                UpdateAccumulatedPosition(Notification, vector2{X := 0.6, Y := CurrentY})
                set CurrentY += AccumulatedYSpacing

    # Actualiza la posición de una notificación acumulada específica
    UpdateAccumulatedPosition(Notification : accumulated_notification_data, NewPosition : vector2):void =
        # Actualizar la posición en el canvas
        if (SlotToUpdate := Notification.Canvas.Slots[0]):
            NewSlot := canvas_slot{
                Anchors := anchors{
                    Minimum := NewPosition
                    Maximum := NewPosition
                }
                Alignment := vector2{X := 0.5, Y := 0.5}
                Offsets := margin{Left := 5.0, Right := 5.0}
                Widget := Notification.WidgetInstance
            }
            
            Notification.Canvas.RemoveWidget(SlotToUpdate.Widget)
            Notification.Canvas.AddWidget(NewSlot)

    # Sobrescribir RemoveElementFromMap para actualizar posiciones
    RemoveElementFromMap(MaterialType : material_type):void =
        var NewNotifications : [material_type]accumulated_notification_data = map{}
        for (Key -> Value : AccumulatedNotifications, Key <> MaterialType):
            if (set NewNotifications[Key] = Value) {}
        set AccumulatedNotifications = NewNotifications
        
        # Actualizar posiciones después de remover
        UpdateAccumulatedPositions()

    # Creates text widget for notification
    CreateNotification(Value : int, Position: vector2, MaterialType : material_type):?tuple(canvas, text_block, widget) =
        NotificationText : text_block = text_block{
            DefaultText := StringToMessage(" +{FormatCurrency(Value)}")
            DefaultTextColor := NamedColors.White
            DefaultShadowColor := NamedColors.Black
            DefaultJustification := text_justification.Center
            DefaultShadowOffset := option{vector2{ X := 2.0, Y := 2.0}}
            DefaultShadowOpacity := 0.5
            DefaultTextOpacity := 1.0
        }

        NotificationIcon : texture_block = texture_block{
            DefaultImage := GetTextureFromMaterial(MaterialType)
            DefaultDesiredSize := vector2{ X := 32.0, Y := 32.0}
        }

        NotificationWidget : stack_box = stack_box {
            Orientation := orientation.Horizontal
            Slots := array{
                stack_box_slot{
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Widget := NotificationIcon
                }
                stack_box_slot{
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Widget := NotificationText
                }
            }
        }

        # Create canvas for this notification
        NotificationCanvas : canvas = canvas{
            Slots := array{
                canvas_slot{
                    Anchors := anchors{
                        Minimum := vector2{X := Position.X, Y := Position.Y}
                        Maximum := vector2{X := Position.X, Y := Position.Y}
                    }
                    Widget := NotificationWidget
                }
            }
        }
        return option{NotificationCanvas, NotificationText, NotificationWidget}

    UpdateNotification(Agent: agent, Notification : notification_data):void=
        if (SlotToRemove : widget = Notification.Canvas.Slots[0].Widget):
            Notification.Canvas.RemoveWidget(SlotToRemove)
            NewWidget := canvas_slot{
                Anchors := anchors{
                    Minimum := vector2{X := Notification.Position.X, Y := Notification.Position.Y}
                    Maximum := vector2{X := Notification.Position.X, Y := Notification.Position.Y}
                }
                Widget := Notification.Widget
            }
            Notification.Canvas.AddWidget(NewWidget)
        
    # Animates a single notification
    AnimateNotification(Agent : agent, Notification : notification_data)<suspends>:void =
        var ElapsedTime : float = 0.0
        var CurrentPosition : vector2 = Notification.Position
        
        if (PlayerUI := GetPlayerUI[player[Agent]]):
            # Animate upward and fade out
            loop:
                if (ElapsedTime >= Duration):
                    break
                    
                Progress : float = ElapsedTime / Duration
                
                # Calculate side motion using sine wave
                # The sine wave is dampened as the notification rises (multiplied by (1.0 - Progress))
                SideOffset := Sin(Progress * MotionSpeed * PiFloat) * SideMotionAmount * (1.0 - Progress)
                
                # Update position
                set CurrentPosition.Y -= VerticalSpeed          # Constant upward movement
                set CurrentPosition.X = Notification.InitialX + SideOffset  # Subtle side motion
                set Notification.Position = CurrentPosition

                UpdateNotification(Agent, Notification)

                # Update opacity with smooth fade out
                OpacityProgress := 1.0 - Progress
                OpacityInRange := Clamp(OpacityProgress, 0.0, 1.0)
                if (ValidOpacity := type{_X:float where 0.0 <= _X, _X <= 1.0}[OpacityInRange]):
                    Notification.Text.SetTextOpacity(ValidOpacity)
                    Notification.Text.SetShadowOpacity(ValidOpacity)
    
                set ElapsedTime += 0.016  # Approximately 60 FPS
                Sleep(0.016)
            
            # Remove notification
            RemoveNotification(Agent, Notification.ID)

    # Removes a notification
    RemoveNotification(Agent : agent, ID : string):void =
        var NewNotifications : []notification_data = array{}
        
        if (PlayerUI := GetPlayerUI[player[Agent]]):
            for (Notification : ActiveNotifications):
                if (Notification.ID = ID):
                    # Find and remove the canvas containing this notification
                    PlayerUI.RemoveWidget(Notification.Canvas)
                else:
                    set NewNotifications += array{Notification}
                    
            set ActiveNotifications = NewNotifications

    GetTextureFromMaterial(MaterialType : material_type):texture=case(MaterialType) {
        material_type.Money => Textures.resources.coins
        material_type.EXP => Textures.resources.experience
        material_type.Hearts => Textures.resources.Hearts
    }