module Page.Settings exposing (BlindLevelSetting, ChipSetting, Intent(..), ViewData, view)

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
    , startingQuantity : Int
    , startingQuantityInput : String
    , ownedQuantity : Int
    , ownedQuantityInput : String
    , enabled : Bool
    }


type alias BlindLevelSetting =
    { smallBlind : Int
    , bigBlind : Int
    , smallBlindInput : String
    , bigBlindInput : String
    }


type alias ViewData =
    { chipSettings : List ChipSetting
    , blindLevelSettings : List BlindLevelSetting
    , playerCount : Int
    , playerCountInput : String
    }


type Intent
    = ChipToggled Page.Game.ChipColor
    | ChipValueChanged Page.Game.ChipColor String
    | ChipStartingQuantityChanged Page.Game.ChipColor String
    | ChipOwnedQuantityChanged Page.Game.ChipColor String
    | PlayerCountChanged String
    | BlindSmallChanged Int String
    | BlindBigChanged Int String



-- VIEW


view : ViewData -> Theme -> Element.Element Intent
view vd theme =
    let
        colors =
            Theme.getColors theme

        enabledChipSettings =
            List.filter .enabled vd.chipSettings

        startingStackTotal =
            List.sum (List.map (\cs -> cs.value * cs.startingQuantity) enabledChipSettings)
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
            , Element.column
                [ Element.spacing 10 ]
                [ Element.el [ Font.size 16 ] (Element.text "Starting Stack")
                , if List.isEmpty enabledChipSettings then
                    Element.el
                        [ Font.color colors.textSecondary
                        , Font.italic
                        ]
                        (Element.text "Enable at least one chip to configure starting quantities.")

                  else
                    Element.row
                        [ Element.spacing 20
                        , Element.width Element.fill
                        ]
                        (List.map (\cs -> viewStartingQuantitySlot cs colors) enabledChipSettings)
                , Element.el
                    [ Font.size 15
                    , Font.bold
                    ]
                    (Element.text ("Total starting stack value: " ++ String.fromInt startingStackTotal))
                , Element.column
                    [ Element.spacing 10 ]
                    [ Element.el [ Font.size 16 ] (Element.text "Chip Inventory Planner")
                    , Element.row
                        [ Element.spacing 10
                        , Element.width Element.fill
                        ]
                        [ Element.el
                            [ Font.size 14
                            , Element.centerY
                            ]
                            (Element.text "Players")
                        , Input.text
                            [ Element.width (Element.px 60)
                            , Element.padding 5
                            , Font.size 14
                            , Border.width 1
                            , Border.color colors.border
                            , Background.color colors.surface
                            , Font.color colors.text
                            ]
                            { onChange = PlayerCountChanged
                            , text = vd.playerCountInput
                            , placeholder = Just (Input.placeholder [] (Element.text "Players"))
                            , label = Input.labelHidden "Number of players"
                            }
                        ]
                    , if List.isEmpty enabledChipSettings then
                        Element.el
                            [ Font.color colors.textSecondary
                            , Font.italic
                            ]
                            (Element.text "Enable at least one chip to plan chip inventory.")

                      else
                        Element.row
                            [ Element.spacing 20
                            , Element.width Element.fill
                            ]
                            (List.map (\cs -> viewInventorySlot vd.playerCount cs colors) enabledChipSettings)
                    ]
                ]
            ]
        , Element.column
            [ Element.spacing 15 ]
            [ Element.el [ Font.size 16 ] (Element.text "Blind Levels")
            , Element.column
                [ Element.spacing 10 ]
                (List.indexedMap (\i bl -> viewBlindLevelRow i bl colors) vd.blindLevelSettings)
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


viewStartingQuantitySlot : ChipSetting -> Theme.ColorPalette -> Element.Element Intent
viewStartingQuantitySlot cs colors =
    let
        chipElementColor =
            Page.Game.chipColorToElementColor cs.color colors

        textColor =
            Page.Game.getChipTextColor cs.color colors

        chipSize =
            50.0
    in
    Element.column
        [ Element.spacing 8
        , Element.alignTop
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
                    , value = Just cs.value
                    , textColor = textColor
                    }
                )
            )
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
            { onChange = ChipStartingQuantityChanged cs.color
            , text = cs.startingQuantityInput
            , placeholder = Just (Input.placeholder [] (Element.text "Qty"))
            , label = Input.labelHidden ("Starting quantity for chip value " ++ String.fromInt cs.value)
            }
        ]


viewInventorySlot : Int -> ChipSetting -> Theme.ColorPalette -> Element.Element Intent
viewInventorySlot playerCount cs colors =
    let
        chipElementColor =
            Page.Game.chipColorToElementColor cs.color colors

        chipSize =
            50.0

        usedCount =
            playerCount * cs.startingQuantity

        leftCount =
            cs.ownedQuantity - usedCount
    in
    Element.column
        [ Element.spacing 8
        , Element.alignTop
        , Element.width (Element.px 80)
        ]
        [ Element.el
            [ Element.centerX
            , Element.width (Element.px (round chipSize))
            , Element.height (Element.px (round chipSize))
            ]
            (Element.html
                (Icons.coinStack
                    { size = chipSize
                    , color = chipElementColor
                    }
                )
            )
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
            { onChange = ChipOwnedQuantityChanged cs.color
            , text = cs.ownedQuantityInput
            , placeholder = Just (Input.placeholder [] (Element.text "Owned"))
            , label = Input.labelHidden "Owned quantity for chip color"
            }
        , Element.paragraph
            [ Font.size 13
            , Font.color colors.textSecondary
            , Element.centerX
            ]
            [ Element.text ("(" ++ String.fromInt usedCount ++ " used)") ]
        , Element.paragraph
            [ Font.size 13
            , Font.color colors.textSecondary
            , Element.centerX
            ]
            [ Element.text ("(" ++ String.fromInt leftCount ++ " left)") ]
        ]


viewBlindLevelRow : Int -> BlindLevelSetting -> Theme.ColorPalette -> Element.Element Intent
viewBlindLevelRow index bl colors =
    let
        inputAttrs =
            [ Element.width (Element.px 80)
            , Element.padding 5
            , Font.size 14
            , Border.width 1
            , Border.color colors.border
            , Background.color colors.surface
            , Font.color colors.text
            ]
    in
    Element.row
        [ Element.spacing 10
        , Element.width Element.fill
        ]
        [ Element.el
            [ Element.width (Element.px 60)
            , Font.size 14
            ]
            (Element.text ("Level " ++ String.fromInt (index + 1)))
        , Input.text
            inputAttrs
            { onChange = BlindSmallChanged index
            , text = bl.smallBlindInput
            , placeholder = Just (Input.placeholder [] (Element.text "SB"))
            , label = Input.labelHidden ("Small blind level " ++ String.fromInt (index + 1))
            }
        , Element.el [ Font.size 14 ] (Element.text "/")
        , Input.text
            inputAttrs
            { onChange = BlindBigChanged index
            , text = bl.bigBlindInput
            , placeholder = Just (Input.placeholder [] (Element.text "BB"))
            , label = Input.labelHidden ("Big blind level " ++ String.fromInt (index + 1))
            }
        ]
