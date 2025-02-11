using { user_interface }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { Utils }

# Interface for displaying currencies
currency_display_interface := class<final><unique>(widget_base):
    Manager : CurrencyManager
    
    # Map to store text blocks for each currency
    var CurrencyTexts : [string]text_block = map{}
    
    CreateCanvas<override>():canvas =
        MainContainer := stack_box{
            Orientation := orientation.Vertical
            Slots := array{}
        }

        # Create text displays for each currency
        for (Currency : Manager.Currencies, Currency.ShowWidget?):
            Print("Showing currency: {Currency.ID}")
            CurrencyText := text_block{
                DefaultText := StringToMessage("{Currency.Prefix}{Currency.InitialAmount}")
                DefaultTextColor := NamedColors.White
                DefaultShadowColor := NamedColors.Black
                DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}
                DefaultShadowOpacity := 0.5
            }

            CurrencyTexture := texture_block{
                DefaultImage := Manager.GetCurrencyTexture(Currency.Texture)
                DefaultDesiredSize := vector2{ X := 256.0, Y := 64.0}
            }

            if (set CurrencyTexts[Currency.ID] = CurrencyText) {}

            CurrencyDisplay := overlay{
                Slots := array{
                    overlay_slot{
                        Widget := CurrencyTexture
                        HorizontalAlignment := horizontal_alignment.Fill
                        VerticalAlignment := vertical_alignment.Fill
                    }
                    overlay_slot{
                        Widget := CurrencyText
                        HorizontalAlignment := horizontal_alignment.Center
                        VerticalAlignment := vertical_alignment.Center
                        Padding := margin{Left := Currency.TextOffset}
                    }
                }
            }

            MainContainer.AddWidget(stack_box_slot{
                Widget := CurrencyDisplay
                HorizontalAlignment := horizontal_alignment.Right
                Padding := margin{Top := 5.0, Bottom := 5.0}
            })

        return canvas{
            Slots := array{
                canvas_slot{
                    Widget := MainContainer
                    Anchors := anchors{Minimum := vector2{X := 0.03, Y := 0.5}, Maximum := vector2{X := 0.03, Y := 0.5}}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    Offsets := margin{Top := 50.0, Right := 50.0}
                }
            }
        }

    # Update the display for a specific currency
    UpdateCurrencyDisplay(CurrencyID : string, Amount : int):void =
        if (TextBlock := CurrencyTexts[CurrencyID]):
            for (Currency : Manager.Currencies, Currency.ShowWidget?, Currency.ID = CurrencyID):
                TextBlock.SetText(StringToMessage("{Currency.Prefix}{FormatCurrency(Amount)}"))