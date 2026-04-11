module Page.Game exposing (Blind, BlindLevels, Chip(..), ChipColor(..), Intent(..), Seconds, TimerState(..), ViewData, advanceBlindLevels, blindLevelsCurrent, blindLevelsFromList, blindLevelsHasNext, blindLevelsHasPrevious, canAddBuyIn, chipColorToElementColor, currentBlindNumber, defaultBlindLevels, getChipTextColor, isPlayerInBuyIns, rewindBlindLevels, subscriptions, upcomingBlinds, view)

import Element
import Element.Background
import Element.Font
import Element.Input
import Html
import Html.Attributes
import Html.Events
import Icons
import Marquee
import Player exposing (Player)
import PokerHandRanking
import Theme exposing (Theme)
import Time



-- MODEL


type alias ViewData =
    { chips : List Chip
    , chipQuantities : List ChipQuantity
    , blindLevels : BlindLevels
    , blindDuration : Seconds
    , blindDurationInput : String
    , remainingTime : Seconds
    , timerState : TimerState
    , activeRankingIndex : Maybe Int
    , selectedPlayerForBuyIn : Maybe Player
    , roster : List Player
    , initialBuyIn : Int
    , buyIns : List Player
    , buyInTimerDuration : Seconds
    , buyInTimerDurationInput : String
    , buyInRemainingTime : Seconds
    , buyInTimerState : TimerState
    , buyInListCollapsed : Bool
    , animateGameChips : Bool
    }


type alias Seconds =
    Int


type alias Blind =
    { smallBlind : Int
    , bigBlind : Int
    }


type BlindLevels
    = BlindLevels
        { previous : List Blind
        , current : Blind
        , next : List Blind
        }


defaultBlinds : List Blind
defaultBlinds =
    [ { smallBlind = 5, bigBlind = 10 }
    , { smallBlind = 10, bigBlind = 20 }
    , { smallBlind = 15, bigBlind = 30 }
    , { smallBlind = 20, bigBlind = 40 }
    , { smallBlind = 25, bigBlind = 50 }
    , { smallBlind = 40, bigBlind = 80 }
    , { smallBlind = 60, bigBlind = 120 }
    , { smallBlind = 100, bigBlind = 200 }
    , { smallBlind = 150, bigBlind = 300 }
    , { smallBlind = 200, bigBlind = 400 }
    ]


defaultBlindLevels : BlindLevels
defaultBlindLevels =
    case blindLevelsFromList defaultBlinds of
        Just levels ->
            levels

        Nothing ->
            BlindLevels
                { previous = []
                , current = { smallBlind = 0, bigBlind = 0 }
                , next = []
                }


blindLevelsFromList : List Blind -> Maybe BlindLevels
blindLevelsFromList blinds =
    case blinds of
        current :: rest ->
            Just (BlindLevels { previous = [], current = current, next = rest })

        [] ->
            Nothing


blindLevelsHasNext : BlindLevels -> Bool
blindLevelsHasNext (BlindLevels levels) =
    not (List.isEmpty levels.next)


blindLevelsHasPrevious : BlindLevels -> Bool
blindLevelsHasPrevious (BlindLevels levels) =
    not (List.isEmpty levels.previous)


advanceBlindLevels : BlindLevels -> BlindLevels
advanceBlindLevels ((BlindLevels levels) as blindLevels) =
    case levels.next of
        nextBlind :: rest ->
            BlindLevels
                { previous = levels.current :: levels.previous
                , current = nextBlind
                , next = rest
                }

        [] ->
            blindLevels


rewindBlindLevels : BlindLevels -> BlindLevels
rewindBlindLevels ((BlindLevels levels) as blindLevels) =
    case levels.previous of
        prevBlind :: rest ->
            BlindLevels
                { previous = rest
                , current = prevBlind
                , next = levels.current :: levels.next
                }

        [] ->
            blindLevels


blindLevelsCurrent : BlindLevels -> Blind
blindLevelsCurrent (BlindLevels levels) =
    levels.current


upcomingBlinds : BlindLevels -> List Blind
upcomingBlinds (BlindLevels levels) =
    levels.next


currentBlindNumber : BlindLevels -> Int
currentBlindNumber (BlindLevels levels) =
    List.length levels.previous + 1


type TimerState
    = Running
    | Paused
    | Stopped
    | Expired


type ChipColor
    = White
    | Red
    | Blue
    | Green
    | Black


type Chip
    = Chip ChipColor Int


type alias ChipQuantity =
    { color : ChipColor
    , quantity : Int
    }


chipColorToElementColor : ChipColor -> Theme.ColorPalette -> Element.Color
chipColorToElementColor chipColor colors =
    case chipColor of
        White ->
            colors.chipWhite

        Red ->
            colors.chipRed

        Blue ->
            colors.chipBlue

        Green ->
            colors.chipGreen

        Black ->
            colors.chipBlack


getChipTextColor : ChipColor -> Theme.ColorPalette -> Element.Color
getChipTextColor chipColor colors =
    case chipColor of
        White ->
            colors.chipTextOnLight

        Black ->
            colors.chipTextOnDark

        _ ->
            colors.text


getTimerBackgroundColor : Theme -> Theme.ColorPalette -> Element.Color
getTimerBackgroundColor theme colors =
    case theme of
        Theme.Light ->
            colors.timerBackground

        Theme.Dark ->
            colors.surface


getBigBlindBackgroundColor : Theme -> Theme.ColorPalette -> Element.Color
getBigBlindBackgroundColor theme colors =
    case theme of
        Theme.Light ->
            colors.bigBlindBackground

        Theme.Dark ->
            colors.surface


getSmallBlindBackgroundColor : Theme -> Theme.ColorPalette -> Element.Color
getSmallBlindBackgroundColor theme colors =
    case theme of
        Theme.Light ->
            colors.smallBlindBackground

        Theme.Dark ->
            colors.surface



-- UPDATE


isPlayerInBuyIns : Player -> List Player -> Bool
isPlayerInBuyIns player buyIns =
    List.member player buyIns


canAddBuyIn : ViewData -> Bool
canAddBuyIn vd =
    vd.buyInTimerState
        /= Expired
        && vd.selectedPlayerForBuyIn
        /= Nothing
        && (case vd.selectedPlayerForBuyIn of
                Just player ->
                    not (isPlayerInBuyIns player vd.buyIns)

                Nothing ->
                    False
           )


type Intent
    = NoOp
    | BlindDurationChanged String
    | TimerTick Time.Posix
    | StartPauseTimer
    | ResetTimer
    | BlindIndexUp
    | BlindIndexDown
    | RankingTimerTick Time.Posix
    | GenerateRandomRanking Int
    | StartNextBlind
    | BuyInPlayerSelected (Maybe Player)
    | BuyInDurationChanged String
    | AddBuyIn
    | RemoveBuyIn Int
    | BuyInTimerTick Time.Posix
    | StartPauseBuyInTimer
    | ResetBuyInTimer
    | ToggleBuyInList


type alias Msg =
    Intent



-- VIEW


view : ViewData -> Theme -> Element.Element Intent
view vd theme =
    let
        colors =
            Theme.getColors theme

        tableSize =
            800.0

        cardSize =
            50.0
    in
    viewGameLayout vd theme colors tableSize cardSize


viewGameLayout : ViewData -> Theme -> Theme.ColorPalette -> Float -> Float -> Element.Element Msg
viewGameLayout vd theme colors tableSize cardSize =
    Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.padding 20
        , Element.Font.color colors.text
        ]
        [ viewMainArea vd theme colors tableSize cardSize
        , viewFooter colors
        ]


viewMainArea : ViewData -> Theme -> Theme.ColorPalette -> Float -> Float -> Element.Element Msg
viewMainArea vd theme colors tableSize cardSize =
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.inFront (viewBlindsOverlay vd theme colors)
        , Element.inFront (viewRankingOverlay cardSize colors vd.activeRankingIndex)
        , Element.inFront (viewBuyInOverlay vd theme colors)
        ]
        (viewTableArea vd theme colors tableSize)


viewTableArea : ViewData -> Theme -> Theme.ColorPalette -> Float -> Element.Element Msg
viewTableArea vd theme colors tableSize =
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.centerX
        , Element.centerY
        ]
        (viewTableWithOverlays vd theme colors tableSize)


viewTableWithOverlays : ViewData -> Theme -> Theme.ColorPalette -> Float -> Element.Element Msg
viewTableWithOverlays vd theme colors tableSize =
    Element.el
        [ Element.width (Element.px (round tableSize))
        , Element.height (Element.px (round tableSize))
        , Element.centerX
        , Element.inFront (viewPotOverlay vd colors)
        , Element.inFront (viewCenterBlindsOverlay vd theme colors)
        , Element.inFront (viewChipsOverlay vd colors)
        ]
        (viewPokerTable colors)


viewBlindsOverlay : ViewData -> Theme -> Theme.ColorPalette -> Element.Element Msg
viewBlindsOverlay vd theme colors =
    Element.el
        [ Element.width Element.shrink
        , Element.alignTop
        , Element.paddingEach { top = 30, right = 0, bottom = 0, left = 0 }
        ]
        (viewBlindsSection vd theme colors)


viewRankingOverlay : Float -> Theme.ColorPalette -> Maybe Int -> Element.Element Msg
viewRankingOverlay cardSize colors activeRankingIndex =
    Element.el
        [ Element.width Element.shrink
        , Element.alignTop
        , Element.alignRight
        , Element.paddingEach { top = 30, right = 20, bottom = 0, left = 0 }
        ]
        (PokerHandRanking.view cardSize colors activeRankingIndex)


viewBuyInOverlay : ViewData -> Theme -> Theme.ColorPalette -> Element.Element Msg
viewBuyInOverlay vd theme colors =
    Element.el
        [ Element.width Element.shrink
        , Element.alignTop
        , Element.moveDown 550
        , Element.paddingEach { top = 0, right = 0, bottom = 0, left = 10 }
        ]
        (viewBuyInSection vd theme colors)


viewPotOverlay : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewPotOverlay vd colors =
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.centerX
        , Element.centerY
        ]
        (viewPriceMoney (calculateTotalPot vd.roster vd.initialBuyIn vd.buyIns) colors)


viewCenterBlindsOverlay : ViewData -> Theme -> Theme.ColorPalette -> Element.Element Msg
viewCenterBlindsOverlay vd theme colors =
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.centerX
        , Element.centerY
        ]
        (viewCenterBlinds vd theme colors)


viewChipsOverlay : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewChipsOverlay vd colors =
    Element.el
        [ Element.width Element.fill
        , Element.alignBottom
        ]
        (viewChips vd colors)


viewFooter : Theme.ColorPalette -> Element.Element Msg
viewFooter colors =
    Element.el
        [ Element.width Element.fill
        , Element.Background.color colors.surface
        ]
        (viewFooterMarquee colors)


viewBlindsSection : ViewData -> Theme -> Theme.ColorPalette -> Element.Element Msg
viewBlindsSection vd theme colors =
    Element.el
        [ Element.width Element.shrink
        , Element.padding 20
        , Element.alignTop
        ]
        (viewLeftControls vd theme colors)


viewLeftControls : ViewData -> Theme -> Theme.ColorPalette -> Element.Element Msg
viewLeftControls vd theme colors =
    let
        isInputDisabled =
            vd.timerState /= Stopped

        progress =
            if vd.blindDuration > 0 then
                toFloat vd.remainingTime / toFloat vd.blindDuration

            else
                0.0

        timerSize =
            250.0

        timerFaceColor =
            getTimerBackgroundColor theme colors

        timerArmColor =
            colors.primary

        timerDurationMinutes =
            toFloat vd.blindDuration / 60.0

        controlButtons =
            case vd.timerState of
                Expired ->
                    viewBlinkingStartNextBlindButton vd colors

                _ ->
                    Element.row
                        [ Element.spacing 10
                        , Element.alignTop
                        , Element.alignLeft
                        ]
                        [ Element.Input.button
                            [ Element.padding 10
                            , Element.Background.color colors.primary
                            , Element.Font.color colors.buttonText
                            ]
                            { onPress = Just StartPauseTimer
                            , label =
                                Element.text
                                    (case vd.timerState of
                                        Running ->
                                            "Pause"

                                        Paused ->
                                            "Start"

                                        Stopped ->
                                            "Start"

                                        Expired ->
                                            "Start"
                                    )
                            }
                        , Element.Input.button
                            [ Element.padding 10
                            , Element.Background.color colors.primary
                            , Element.Font.color colors.buttonText
                            ]
                            { onPress = Just ResetTimer
                            , label = Element.text "Reset"
                            }
                        ]
    in
    Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.spacing 20
        ]
        [ Element.wrappedRow
            [ Element.width Element.fill
            , Element.spacing 20
            ]
            [ Element.column
                [ Element.width Element.shrink
                , Element.spacing 10
                , Element.alignTop
                ]
                [ controlButtons
                , Element.column
                    [ Element.spacing 5
                    , Element.alignLeft
                    ]
                    [ Element.el
                        [ Element.Font.size 16
                        ]
                        (Element.text "Blind Duration:")
                    , Element.Input.text
                        [ Element.width (Element.px 80)
                        , Element.alignLeft
                        , Element.padding 8
                        , Element.Background.color colors.background
                        , Element.Font.color colors.text
                        , Element.htmlAttribute
                            (if isInputDisabled then
                                Html.Attributes.disabled True

                             else
                                Html.Attributes.disabled False
                            )
                        ]
                        { onChange = BlindDurationChanged
                        , text = vd.blindDurationInput
                        , placeholder = Nothing
                        , label = Element.Input.labelHidden "Blind duration in minutes"
                        }
                    ]
                ]
            , Element.el
                [ Element.width (Element.px (round timerSize))
                ]
                (Element.html
                    (Icons.timer
                        { size = timerSize
                        , backgroundColor = timerFaceColor
                        , armColor = timerArmColor
                        , progress = progress
                        , duration = timerDurationMinutes
                        }
                    )
                )
            ]
        , viewManualBlindsAdvance vd colors
        , viewRightLevels vd
        ]


viewCenterBlinds : ViewData -> Theme -> Theme.ColorPalette -> Element.Element Msg
viewCenterBlinds vd theme colors =
    let
        blind =
            blindLevelsCurrent vd.blindLevels

        iconSize =
            140.0
    in
    Element.row
        [ Element.centerX
        ]
        [ Element.html
            (Icons.bigBlind
                { size = iconSize
                , backgroundColor = getBigBlindBackgroundColor theme colors
                , labelTextColor = colors.bigBlindText
                , valueTextColor = colors.bigBlindText
                , value = blind.bigBlind
                }
            )
        , Element.html
            (Icons.smallBlind
                { size = iconSize
                , backgroundColor = getSmallBlindBackgroundColor theme colors
                , labelTextColor = colors.smallBlindText
                , valueTextColor = colors.smallBlindText
                , value = blind.smallBlind
                }
            )
        ]


viewManualBlindsAdvance : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewManualBlindsAdvance vd colors =
    Element.column
        [ Element.spacing 10
        , Element.alignLeft
        ]
        [ Element.row
            [ Element.spacing 10
            , Element.alignLeft
            ]
            [ Element.Input.button
                [ Element.padding 10
                , Element.Background.color colors.primary
                , Element.Font.color colors.buttonText
                ]
                { onPress =
                    if blindLevelsHasNext vd.blindLevels then
                        Just BlindIndexUp

                    else
                        Nothing
                , label = Element.text "↑"
                }
            , Element.Input.button
                [ Element.padding 10
                , Element.Background.color colors.primary
                , Element.Font.color colors.buttonText
                ]
                { onPress =
                    if blindLevelsHasPrevious vd.blindLevels then
                        Just BlindIndexDown

                    else
                        Nothing
                , label = Element.text "↓"
                }
            ]
        ]


viewBlinkingStartNextBlindButton : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewBlinkingStartNextBlindButton vd colors =
    let
        canAdvance =
            blindLevelsHasNext vd.blindLevels

        blinkAnimationStyle =
            Html.Attributes.style "animation" "blink 1s infinite"

        blinkKeyframes =
            Html.node "style"
                []
                [ Html.text
                    ("@keyframes blink {\n"
                        ++ "  0% { opacity: 1; }\n"
                        ++ "  50% { opacity: 0.3; }\n"
                        ++ "  100% { opacity: 1; }\n"
                        ++ "}"
                    )
                ]
    in
    Element.column
        [ Element.spacing 0 ]
        [ Element.html blinkKeyframes
        , Element.Input.button
            [ Element.padding 10
            , Element.Background.color colors.primary
            , Element.Font.color colors.buttonText
            , Element.htmlAttribute blinkAnimationStyle
            ]
            { onPress =
                if canAdvance then
                    Just StartNextBlind

                else
                    Nothing
            , label = Element.text "Start Next Blind"
            }
        ]


viewRightLevels : ViewData -> Element.Element Msg
viewRightLevels vd =
    let
        upcomingBlindsList =
            vd.blindLevels
                |> upcomingBlinds
                |> List.take 3

        currentLevelNumberIndex =
            currentBlindNumber vd.blindLevels
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing 20
        , Element.alignTop
        ]
        [ Element.column
            [ Element.spacing 10
            , Element.width Element.fill
            ]
            [ Element.el
                [ Element.Font.size 14
                , Element.Font.bold
                ]
                (Element.text "Upcoming Levels:")
            , Element.column
                [ Element.spacing 5 ]
                (List.indexedMap
                    (\idx upcomingBlind ->
                        Element.el
                            [ Element.Font.size 18
                            , Element.Font.bold
                            , Element.Font.family [ Element.Font.monospace ]
                            , Element.width Element.fill
                            ]
                            (Element.text
                                ("Level "
                                    ++ String.fromInt (currentLevelNumberIndex + idx + 1)
                                    ++ ":  "
                                    ++ formatBlindValue upcomingBlind.bigBlind
                                    ++ " / "
                                    ++ formatBlindValue upcomingBlind.smallBlind
                                )
                            )
                    )
                    upcomingBlindsList
                )
            ]
        ]


chipValue : Chip -> Int
chipValue chip =
    case chip of
        Chip _ val ->
            val


viewChips : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewChips vd colors =
    Element.el
        [ Element.width Element.fill
        , Element.centerX
        ]
        (Element.row
            [ Element.spacing 20
            , Element.centerX
            ]
            (List.map (\chip -> viewChip chip vd colors) (List.sortBy chipValue vd.chips))
        )


viewChip : Chip -> ViewData -> Theme.ColorPalette -> Element.Element Msg
viewChip chip vd colors =
    let
        ( chipColor, value ) =
            case chip of
                Chip color val ->
                    ( color, val )

        quantity =
            getChipQuantity chipColor vd.chipQuantities

        chipElementColor =
            chipColorToElementColor chipColor colors

        chipSize =
            150.0

        spinSpeed =
            3.0

        textColor =
            getChipTextColor chipColor colors
    in
    Element.column
        [ Element.spacing 8
        , Element.centerX
        ]
        [ Element.html
            (Icons.pokerChip
                { size = chipSize
                , color = chipElementColor
                , spinSpeed = spinSpeed
                , animated = vd.animateGameChips
                , value = Just value
                , textColor = textColor
                }
            )
        , if quantity > 0 then
            Element.el
                [ Element.centerX
                , Element.Font.size 20
                , Element.Font.bold
                ]
                (Element.text ("x" ++ String.fromInt quantity))

          else
            Element.none
        ]


getChipQuantity : ChipColor -> List ChipQuantity -> Int
getChipQuantity targetColor chipQuantities =
    chipQuantities
        |> List.filter (\entry -> entry.color == targetColor)
        |> List.head
        |> Maybe.map .quantity
        |> Maybe.withDefault 0


viewPokerTable : Theme.ColorPalette -> Element.Element Msg
viewPokerTable colors =
    let
        tableColor =
            colors.pokerTable

        tableSize =
            800.0
    in
    Element.html
        (Icons.pokerTable
            { size = tableSize
            , color = tableColor
            }
        )


viewPriceMoney : Int -> Theme.ColorPalette -> Element.Element Msg
viewPriceMoney amount colors =
    let
        dollarSize =
            60.0

        dollarColor =
            colors.prizeGold
    in
    Element.row
        [ Element.centerX
        , Element.centerY
        ]
        [ Element.el
            [ Element.Font.size 48
            , Element.Font.bold
            , Element.Font.color colors.text
            , Element.Font.family [ Element.Font.monospace ]
            , Element.paddingEach { top = 0, right = 20, bottom = 0, left = 0 }
            ]
            (Element.text (String.fromInt amount))
        , Element.html
            (Icons.dollar
                { size = dollarSize
                , color = dollarColor
                }
            )
        ]


viewBuyInSection : ViewData -> Theme -> Theme.ColorPalette -> Element.Element Msg
viewBuyInSection vd _ colors =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 10
        , Element.padding 12
        ]
        [ Element.el
            [ Element.Font.size 16
            , Element.Font.bold
            ]
            (Element.text "Buy-In Registration")
        , viewBuyInTimerControls vd colors
        , viewBuyInPlayerSelector vd colors
        , viewBuyInList vd colors
        ]


viewBuyInTimerControls : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewBuyInTimerControls vd colors =
    let
        isInputDisabled =
            vd.buyInTimerState /= Stopped
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing 5
        , Element.alignLeft
        ]
        [ Element.el
            [ Element.Font.size 14
            ]
            (Element.text "Buy-In Timer Duration:")
        , Element.Input.text
            [ Element.width (Element.px 80)
            , Element.alignLeft
            , Element.padding 8
            , Element.Background.color colors.background
            , Element.Font.color colors.text
            , Element.htmlAttribute
                (if isInputDisabled then
                    Html.Attributes.disabled True

                 else
                    Html.Attributes.disabled False
                )
            ]
            { onChange = BuyInDurationChanged
            , text = vd.buyInTimerDurationInput
            , placeholder = Nothing
            , label = Element.Input.labelHidden "Buy-in timer duration in minutes"
            }
        , Element.row
            [ Element.spacing 10
            , Element.alignLeft
            ]
            [ Element.Input.button
                [ Element.padding 10
                , Element.Background.color colors.primary
                , Element.Font.color colors.buttonText
                ]
                { onPress = Just StartPauseBuyInTimer
                , label =
                    Element.text
                        (case vd.buyInTimerState of
                            Running ->
                                "Pause"

                            Paused ->
                                "Start"

                            Stopped ->
                                "Start"

                            Expired ->
                                "Start"
                        )
                }
            , Element.Input.button
                [ Element.padding 10
                , Element.Background.color colors.primary
                , Element.Font.color colors.buttonText
                ]
                { onPress = Just ResetBuyInTimer
                , label = Element.text "Reset"
                }
            , Element.el
                [ Element.Font.size 24
                , Element.Font.bold
                , Element.Font.family [ Element.Font.monospace ]
                , Element.paddingXY 10 0
                ]
                (Element.text (formatTime vd.buyInRemainingTime))
            ]
        ]


viewBuyInPlayerSelector : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewBuyInPlayerSelector vd colors =
    let
        availablePlayers =
            vd.roster
                |> List.filter (\player -> not (isPlayerInBuyIns player vd.buyIns))

        canAdd =
            canAddBuyIn vd

        isSelected : Player -> Bool
        isSelected player =
            case vd.selectedPlayerForBuyIn of
                Just selectedPlayer ->
                    selectedPlayer == player

                Nothing ->
                    False

        selectHtml =
            Html.select
                [ Html.Attributes.style "width" "100%"
                , Html.Attributes.style "padding" "8px"
                , Html.Attributes.style "background-color"
                    (if vd.buyInTimerState == Expired then
                        "#cccccc"

                     else
                        "transparent"
                    )
                , Html.Attributes.style "color"
                    (if vd.buyInTimerState == Expired then
                        "#666666"

                     else
                        "inherit"
                    )
                , Html.Attributes.disabled (vd.buyInTimerState == Expired)
                , Html.Events.onInput
                    (\val ->
                        if val == "" then
                            BuyInPlayerSelected Nothing

                        else
                            availablePlayers
                                |> List.filter (\p -> Player.getName p == val)
                                |> List.head
                                |> Maybe.map (\p -> BuyInPlayerSelected (Just p))
                                |> Maybe.withDefault (BuyInPlayerSelected Nothing)
                    )
                ]
                (Html.option
                    [ Html.Attributes.value ""
                    , Html.Attributes.selected (vd.selectedPlayerForBuyIn == Nothing)
                    ]
                    [ Html.text "Select a player..." ]
                    :: List.map
                        (\player ->
                            let
                                playerName =
                                    Player.getName player
                            in
                            Html.option
                                [ Html.Attributes.value playerName
                                , Html.Attributes.selected (isSelected player)
                                ]
                                [ Html.text playerName ]
                        )
                        availablePlayers
                )
    in
    Element.row
        [ Element.width Element.fill
        , Element.spacing 10
        ]
        [ Element.el
            [ Element.width (Element.fillPortion 3)
            ]
            (Element.html selectHtml)
        , Element.Input.button
            [ Element.padding 8
            , Element.width (Element.fillPortion 1)
            , Element.Background.color
                (if canAdd then
                    colors.primary

                 else
                    colors.surface
                )
            , Element.Font.color
                (if canAdd then
                    colors.text

                 else
                    colors.textSecondary
                )
            ]
            { onPress =
                if canAdd then
                    Just AddBuyIn

                else
                    Nothing
            , label = Element.text "Add"
            }
        ]


viewBuyInList : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewBuyInList vd colors =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 10
        ]
        [ Element.row
            [ Element.width Element.fill
            , Element.spacing 10
            ]
            [ Element.el
                [ Element.Font.size 16
                , Element.Font.bold
                ]
                (Element.text "Registered Buy-Ins:")
            , viewBuyInCollapseExpandButton vd colors
            ]
        , if List.isEmpty vd.buyIns then
            Element.el
                [ Element.Font.color colors.textSecondary
                , Element.Font.italic
                ]
                (Element.text "No buy-ins registered yet.")

          else if vd.buyInListCollapsed then
            Element.el
                [ Element.Font.color colors.textSecondary
                , Element.Font.italic
                ]
                (Element.text (String.fromInt (List.length vd.buyIns) ++ " buy-ins"))

          else
            Element.column
                [ Element.width Element.fill
                , Element.spacing 8
                ]
                (List.indexedMap (\index buyIn -> viewBuyInRow index buyIn colors) vd.buyIns)
        ]


viewBuyInRow : Int -> Player -> Theme.ColorPalette -> Element.Element Msg
viewBuyInRow index buyInPlayer colors =
    let
        playerName =
            Player.getName buyInPlayer
    in
    Element.row
        [ Element.width Element.fill
        , Element.spacing 10
        ]
        [ Element.el
            [ Element.width Element.fill
            ]
            (Element.text ("- " ++ playerName))
        , Element.Input.button
            [ Element.padding 8
            , Element.Background.color colors.accent
            , Element.Font.color colors.buttonText
            ]
            { onPress = Just (RemoveBuyIn index)
            , label = Element.text "Remove"
            }
        ]


viewBuyInCollapseExpandButton : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewBuyInCollapseExpandButton vd colors =
    if not (List.isEmpty vd.buyIns) then
        Element.Input.button
            [ Element.padding 4
            , Element.width (Element.px 40)
            , Element.height (Element.px 40)
            , Element.Background.color colors.primary
            , Element.Font.color colors.buttonText
            ]
            { onPress = Just ToggleBuyInList
            , label =
                Element.el
                    [ Element.centerX
                    , Element.centerY
                    ]
                    (Element.text
                        (if vd.buyInListCollapsed then
                            "↓"

                         else
                            "↑"
                        )
                    )
            }

    else
        Element.none


viewFooterMarquee : Theme.ColorPalette -> Element.Element Msg
viewFooterMarquee _ =
    Element.html
        (Html.div
            [ Html.Attributes.style "position" "fixed"
            , Html.Attributes.style "bottom" "4px"
            , Html.Attributes.style "left" "0"
            , Html.Attributes.style "width" "100%"
            , Html.Attributes.style "z-index" "2"
            ]
            [ Element.layoutWith
                { options = [ Element.noStaticStyleSheet ] }
                []
                (Marquee.view
                    [ "Blinds move clockwise"
                    , "You must at least match the big blind to play"
                    , "A raise must be at least as big as the last raise"
                    , "Only use the chips in front of you for betting"
                    , "Place chips clearly in the pot"
                    , "Don't say what you folded"
                    , "Don't show your cards before showdown"
                    , "Don't act before your turn"
                    , "Don't touch other players' chips or cards"
                    , "Keep your cards on the table while playing"
                    ]
                )
            ]
        )



-- Helper functions


calculateTotalPot : List Player -> Int -> List Player -> Int
calculateTotalPot players buyIn buyIns =
    (List.length players + List.length buyIns) * buyIn


formatTime : Int -> String
formatTime seconds =
    let
        minutes =
            seconds // 60

        secs =
            modBy 60 seconds

        minutesStr =
            if minutes < 10 then
                "0" ++ String.fromInt minutes

            else
                String.fromInt minutes

        secsStr =
            if secs < 10 then
                "0" ++ String.fromInt secs

            else
                String.fromInt secs
    in
    minutesStr ++ ":" ++ secsStr


formatBlindValue : Int -> String
formatBlindValue value =
    let
        valueStr =
            String.fromInt value

        reversed =
            String.reverse valueStr

        buildChunks : String -> List String
        buildChunks str =
            if String.length str <= 3 then
                [ String.reverse str ]

            else
                String.reverse (String.left 3 str)
                    :: buildChunks (String.dropLeft 3 str)
    in
    buildChunks reversed
        |> List.reverse
        |> String.join " "



-- SUBSCRIPTIONS


subscriptions : ViewData -> Sub Msg
subscriptions vd =
    Sub.batch
        [ case vd.timerState of
            Running ->
                Time.every 1000 TimerTick

            Paused ->
                Sub.none

            Stopped ->
                Sub.none

            Expired ->
                Sub.none
        , case vd.buyInTimerState of
            Running ->
                Time.every 1000 BuyInTimerTick

            Paused ->
                Sub.none

            Stopped ->
                Sub.none

            Expired ->
                Sub.none
        , Time.every (15 * 1000) RankingTimerTick
        ]
