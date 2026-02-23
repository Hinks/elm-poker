module Page.Settings exposing (ChipSetting, Intent(..), ViewData, view)

import Element
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Icons
import Page.Game
import Theme exposing (Theme)



-- MODEL


type alias ChipSetting =
    { color : Page.Game.ChipColor
    , value : Int
    , valueInput : String
    , enabled : Bool
    }


type alias ViewData =
    { chipSettings : List ChipSetting
    }


type Intent
    = ChipToggled Page.Game.ChipColor
    | ChipValueChanged Page.Game.ChipColor String



-- VIEW


view : ViewData -> Theme -> Element.Element Intent
view vd theme =
    let
        colors =
            Theme.getColors theme
    in
    Element.column
        [ Element.width Element.fill
        , Element.padding 20
        , Element.spacing 30
        , Font.color colors.text
        ]
        [ Element.el
            [ Font.size 22
            , Font.bold
            ]
            (Element.text "Settings")
        , Element.column
            [ Element.spacing 15 ]
            [ Element.el [ Font.size 16 ] (Element.text "Poker Chips")
            , Element.row
                [ Element.spacing 20 ]
                (List.map (\cs -> viewChipSlot cs colors) vd.chipSettings)
            ]
        ]


viewChipSlot : ChipSetting -> Theme.ColorPalette -> Element.Element Intent
viewChipSlot cs colors =
    let
        chipElementColor =
            Page.Game.chipColorToElementColor cs.color colors

        textColor =
            Page.Game.getChipTextColor cs.color colors

        chipSize =
            50.0

        opacity =
            if cs.enabled then
                1.0

            else
                0.3
    in
    Element.column
        [ Element.spacing 8
        , Element.alignTop
        , Element.alpha opacity
        , Element.width (Element.px 60)
        ]
        [ Element.el
            [ Element.centerX
            , Element.width (Element.px (round chipSize))
            , Element.height (Element.px (round chipSize))
            ]
            (Element.html
                (Icons.pokerChip
                    { size = chipSize
                    , color = chipElementColor
                    , spinSpeed = 0
                    , value = Nothing
                    , textColor = textColor
                    }
                )
            )
        , Input.checkbox
            [ Element.centerX
            , Element.width Element.shrink
            ]
            { onChange = \_ -> ChipToggled cs.color
            , icon = Input.defaultCheckbox
            , checked = cs.enabled
            , label = Input.labelHidden "Enable chip"
            }
        , Input.text
            [ Element.width (Element.px 60)
            , Element.padding 5
            , Font.size 14
            , Element.centerX
            , Border.width 1
            , Border.color colors.border
            , Background.color colors.surface
            , Font.color colors.text
            ]
            { onChange = ChipValueChanged cs.color
            , text = cs.valueInput
            , placeholder = Nothing
            , label = Input.labelHidden "Chip value"
            }
        ]
