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
    | ResetToDefaults
    | ExportSettings
    | ImportSettings



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
        (Font.color colors.text :: rootColumnAttrs)
        [ Element.el
            [ Font.size 22
            , Font.bold
            ]
            (Element.text "Settings")
        , Element.wrappedRow
            layoutColumnsAttrs
            [ viewChipPlannerColumn vd colors enabledChipSettings startingStackTotal
            , viewVerticalDivider colors
            , viewBlindLevelsColumn vd colors
            ]
        , viewDivider colors
        , Element.row
            [ Element.spacing 10 ]
            [ Input.button
                [ Element.padding 10
                , Background.color colors.surface
                , Font.color colors.text
                , Font.size 14
                , Border.rounded 4
                , Border.width 1
                , Border.color colors.border
                ]
                { onPress = Just ExportSettings
                , label = Element.text "Export Settings"
                }
            , Input.button
                [ Element.padding 10
                , Background.color colors.surface
                , Font.color colors.text
                , Font.size 14
                , Border.rounded 4
                , Border.width 1
                , Border.color colors.border
                ]
                { onPress = Just ImportSettings
                , label = Element.text "Import Settings"
                }
            , Input.button
                [ Element.padding 10
                , Background.color colors.removeButton
                , Font.color colors.buttonText
                , Font.size 14
                , Border.rounded 4
                ]
                { onPress = Just ResetToDefaults
                , label = Element.text "Reset to Defaults"
                }
            ]
        ]


rootColumnAttrs : List (Element.Attribute msg)
rootColumnAttrs =
    [ Element.width Element.fill
    , Element.padding 20
    , Element.spacing 30
    ]


layoutColumnsAttrs : List (Element.Attribute msg)
layoutColumnsAttrs =
    [ Element.width Element.fill
    , Element.spacing 24
    , Element.alignTop
    , Element.alignLeft
    ]


plannerColumnAttrs : List (Element.Attribute msg)
plannerColumnAttrs =
    [ Element.spacing 15
    , Element.width Element.shrink
    , Element.alignTop
    , Element.alignLeft
    ]


chipSlotWidth : Int
chipSlotWidth =
    60


chipSlotSpacing : Int
chipSlotSpacing =
    20


chipSize : Float
chipSize =
    50.0


viewChipPlannerColumn : ViewData -> Theme.ColorPalette -> List ChipSetting -> Int -> Element.Element Intent
viewChipPlannerColumn vd colors enabledChipSettings startingStackTotal =
    Element.column
        plannerColumnAttrs
        [ viewSectionTitle "Poker Chips"
        , Element.row
            [ Element.spacing chipSlotSpacing ]
            (List.map (\cs -> viewChipSlot cs colors) vd.chipSettings)
        , viewChipDivider (List.length vd.chipSettings) colors
        , viewStartingStackSection colors enabledChipSettings startingStackTotal
        , viewDivider colors
        , viewInventoryPlannerSection vd colors enabledChipSettings
        ]


viewBlindLevelsColumn : ViewData -> Theme.ColorPalette -> Element.Element Intent
viewBlindLevelsColumn vd colors =
    Element.column
        plannerColumnAttrs
        [ viewSectionTitle "Blind Levels"
        , Element.column
            [ Element.spacing 10 ]
            (List.indexedMap (\i bl -> viewBlindLevelRow i bl colors) vd.blindLevelSettings)
        ]


viewSectionTitle : String -> Element.Element msg
viewSectionTitle title =
    Element.el [ Font.size 16 ] (Element.text title)


viewMutedHint : Theme.ColorPalette -> String -> Element.Element msg
viewMutedHint colors message =
    Element.el
        [ Font.color colors.textSecondary
        , Font.italic
        ]
        (Element.text message)


viewStartingStackSection : Theme.ColorPalette -> List ChipSetting -> Int -> Element.Element Intent
viewStartingStackSection colors enabledChipSettings startingStackTotal =
    Element.column
        [ Element.spacing 10 ]
        [ viewSectionTitle "Starting Stack"
        , if List.isEmpty enabledChipSettings then
            viewMutedHint colors "Enable at least one chip to configure starting quantities."

          else
            Element.row
                [ Element.spacing chipSlotSpacing
                , Element.width Element.fill
                ]
                (List.map (\cs -> viewStartingQuantitySlot cs colors) enabledChipSettings)
        , Element.el
            [ Font.size 15
            , Font.bold
            ]
            (Element.text ("Total starting stack value: " ++ String.fromInt startingStackTotal))
        ]


viewInventoryPlannerSection : ViewData -> Theme.ColorPalette -> List ChipSetting -> Element.Element Intent
viewInventoryPlannerSection vd colors enabledChipSettings =
    Element.column
        [ Element.spacing 10 ]
        [ viewSectionTitle "Chip Inventory Planner"
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
                (textInputAttrs colors chipSlotWidth)
                { onChange = PlayerCountChanged
                , text = vd.playerCountInput
                , placeholder = Just (Input.placeholder [] (Element.text "Players"))
                , label = Input.labelHidden "Number of players"
                }
            ]
        , if List.isEmpty enabledChipSettings then
            viewMutedHint colors "Enable at least one chip to plan chip inventory."

          else
            Element.row
                [ Element.spacing chipSlotSpacing
                , Element.width Element.fill
                ]
                (List.map (\cs -> viewInventorySlot vd.playerCount cs colors) enabledChipSettings)
        ]


textInputAttrs : Theme.ColorPalette -> Int -> List (Element.Attribute msg)
textInputAttrs colors widthPx =
    [ Element.width (Element.px widthPx)
    , Element.padding 5
    , Font.size 14
    , Border.width 1
    , Border.color colors.border
    , Background.color colors.surface
    , Font.color colors.text
    ]


centeredTextInputAttrs : Theme.ColorPalette -> Int -> List (Element.Attribute msg)
centeredTextInputAttrs colors widthPx =
    Element.centerX :: textInputAttrs colors widthPx


viewDivider : Theme.ColorPalette -> Element.Element msg
viewDivider colors =
    Element.el
        [ Element.width Element.fill
        , Element.height (Element.px 1)
        , Background.color colors.border
        ]
        Element.none


viewChipDivider : Int -> Theme.ColorPalette -> Element.Element msg
viewChipDivider chipCount colors =
    let
        dividerWidth =
            (chipCount * chipSlotWidth) + (max 0 (chipCount - 1) * chipSlotSpacing)
    in
    Element.el
        [ Element.width (Element.px dividerWidth)
        , Element.height (Element.px 1)
        , Background.color colors.border
        ]
        Element.none


viewVerticalDivider : Theme.ColorPalette -> Element.Element msg
viewVerticalDivider colors =
    Element.el
        [ Element.width (Element.px 1)
        , Element.height Element.fill
        , Background.color colors.border
        ]
        Element.none


viewChipSlot : ChipSetting -> Theme.ColorPalette -> Element.Element Intent
viewChipSlot cs colors =
    let
        chipElementColor =
            Page.Game.chipColorToElementColor cs.color colors

        textColor =
            Page.Game.getChipTextColor cs.color colors

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
        , Element.width (Element.px chipSlotWidth)
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
            (centeredTextInputAttrs colors chipSlotWidth)
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

    in
    Element.column
        [ Element.spacing 8
        , Element.alignTop
        , Element.width (Element.px chipSlotWidth)
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
            (centeredTextInputAttrs colors chipSlotWidth)
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

        coinStackColor =
            case cs.color of
                Page.Game.Black ->
                    colors.coinStackBlack

                Page.Game.White ->
                    colors.coinStackWhite

                _ ->
                    chipElementColor

        usedCount =
            playerCount * cs.startingQuantity

        leftCount =
            cs.ownedQuantity - usedCount
    in
    Element.column
        [ Element.spacing 8
        , Element.alignTop
        , Element.width (Element.px chipSlotWidth)
        ]
        [ Element.el
            [ Element.centerX
            , Element.width (Element.px (round chipSize))
            , Element.height (Element.px (round chipSize))
            ]
            (Element.html
                (Icons.coinStack
                    { size = chipSize
                    , color = coinStackColor
                    }
                )
            )
        , Input.text
            (centeredTextInputAttrs colors chipSlotWidth)
            { onChange = ChipOwnedQuantityChanged cs.color
            , text = cs.ownedQuantityInput
            , placeholder = Just (Input.placeholder [] (Element.text "Owned"))
            , label = Input.labelHidden "Owned quantity for chip color"
            }
        , Element.el
            [ Font.size 13
            , Font.color colors.textSecondary
            , Element.centerX
            ]
            (Element.text ("(" ++ String.fromInt usedCount ++ " used)"))
        , Element.el
            [ Font.size 13
            , Font.color colors.textSecondary
            , Element.centerX
            ]
            (Element.text ("(" ++ String.fromInt leftCount ++ " left)"))
        ]


viewBlindLevelRow : Int -> BlindLevelSetting -> Theme.ColorPalette -> Element.Element Intent
viewBlindLevelRow index bl colors =
    let
        inputAttrs =
            textInputAttrs colors 80
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
            { onChange = BlindBigChanged index
            , text = bl.bigBlindInput
            , placeholder = Just (Input.placeholder [] (Element.text "BB"))
            , label = Input.labelHidden ("Big blind level " ++ String.fromInt (index + 1))
            }
        , Element.el [ Font.size 14 ] (Element.text "/")
        , Input.text
            inputAttrs
            { onChange = BlindSmallChanged index
            , text = bl.smallBlindInput
            , placeholder = Just (Input.placeholder [] (Element.text "SB"))
            , label = Input.labelHidden ("Small blind level " ++ String.fromInt (index + 1))
            }
        ]
