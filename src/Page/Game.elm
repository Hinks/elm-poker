module Page.Game exposing (Model, Msg, buyInPlayers, init, subscriptions, update, view)

import Element
import Element.Background
import Element.Font
import Element.Input
import Html
import Html.Attributes
import Html.Events
import Icons
import Marquee
import Page.Players exposing (Player)
import PokerHandRanking
import Ports
import Random
import Theme exposing (Theme)
import Time



-- MODEL


type alias Model =
    { chips : List Chip
    , blindLevels : BlindLevels
    , blindDuration : Seconds
    , blindDurationInput : String
    , remainingTime : Seconds
    , timerState : TimerState
    , players : List Player
    , initialBuyIn : Int
    , activeRankingIndex : Maybe Int
    , buyIns : List BuyIn
    , selectedPlayerForBuyIn : Maybe Player
    , buyInTimerDuration : Seconds
    , buyInTimerDurationInput : String
    , buyInRemainingTime : Seconds
    , buyInTimerState : TimerState
    , buyInListCollapsed : Bool
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
    [ { smallBlind = 100, bigBlind = 200 }
    , { smallBlind = 200, bigBlind = 400 }
    , { smallBlind = 300, bigBlind = 600 }
    , { smallBlind = 400, bigBlind = 800 }
    , { smallBlind = 500, bigBlind = 1000 }
    , { smallBlind = 800, bigBlind = 1600 }
    , { smallBlind = 1000, bigBlind = 2000 }
    , { smallBlind = 2000, bigBlind = 4000 }
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


type BuyIn
    = BuyIn Player


init : Maybe Model -> List Player -> Int -> Model
init maybeExistingModel players buyIn =
    case maybeExistingModel of
        Just existingModel ->
            { existingModel
                | players = players
                , initialBuyIn = buyIn
            }

        Nothing ->
            { chips = [ Chip White 50, Chip Red 100, Chip Blue 200, Chip Green 250, Chip Black 500 ]
            , blindLevels = defaultBlindLevels
            , blindDuration = 12 * 60
            , blindDurationInput = "12"
            , remainingTime = 12 * 60
            , timerState = Stopped
            , players = players
            , initialBuyIn = buyIn
            , activeRankingIndex = Just 0
            , buyIns = []
            , selectedPlayerForBuyIn = Nothing
            , buyInTimerDuration = 30 * 60
            , buyInTimerDurationInput = "30"
            , buyInRemainingTime = 30 * 60
            , buyInTimerState = Stopped
            , buyInListCollapsed = True
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


isPlayerInBuyIns : Player -> List BuyIn -> Bool
isPlayerInBuyIns player buyIns =
    List.any
        (\buyIn ->
            case buyIn of
                BuyIn buyInPlayer ->
                    buyInPlayer == player
        )
        buyIns


canAddBuyIn : Model -> Bool
canAddBuyIn model =
    model.buyInTimerState
        /= Expired
        && model.selectedPlayerForBuyIn
        /= Nothing
        && (case model.selectedPlayerForBuyIn of
                Just player ->
                    not (isPlayerInBuyIns player model.buyIns)

                Nothing ->
                    False
           )


type Msg
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        BlindDurationChanged str ->
            if model.timerState == Stopped then
                case String.toInt str of
                    Just minutes ->
                        if minutes > 0 then
                            let
                                durationInSeconds =
                                    minutes * 60
                            in
                            ( { model
                                | blindDurationInput = str
                                , blindDuration = durationInSeconds
                                , remainingTime = durationInSeconds
                              }
                            , Cmd.none
                            )

                        else
                            ( { model | blindDurationInput = str }, Cmd.none )

                    Nothing ->
                        ( { model | blindDurationInput = str }, Cmd.none )

            else
                ( model, Cmd.none )

        TimerTick _ ->
            if model.timerState == Running then
                if model.remainingTime > 0 then
                    ( { model | remainingTime = model.remainingTime - 1 }
                    , Cmd.none
                    )

                else
                    ( { model | timerState = Expired }, Ports.send Ports.BlindTimerAlert )

            else
                ( model, Cmd.none )

        StartPauseTimer ->
            case model.timerState of
                Stopped ->
                    ( { model | timerState = Running }, Cmd.none )

                Paused ->
                    ( { model | timerState = Running }, Cmd.none )

                Running ->
                    ( { model | timerState = Paused }, Cmd.none )

                Expired ->
                    ( model, Cmd.none )

        ResetTimer ->
            ( { model
                | blindLevels = defaultBlindLevels
                , remainingTime = model.blindDuration
                , timerState = Stopped
                , blindDurationInput = String.fromInt (model.blindDuration // 60)
              }
            , Cmd.none
            )

        BlindIndexUp ->
            if blindLevelsHasNext model.blindLevels then
                ( { model
                    | blindLevels = advanceBlindLevels model.blindLevels
                    , remainingTime = model.blindDuration
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        BlindIndexDown ->
            if blindLevelsHasPrevious model.blindLevels then
                ( { model
                    | blindLevels = rewindBlindLevels model.blindLevels
                    , remainingTime = model.blindDuration
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        RankingTimerTick _ ->
            ( model, Random.generate GenerateRandomRanking (Random.int 0 9) )

        GenerateRandomRanking index ->
            ( { model | activeRankingIndex = Just index }, Cmd.none )

        StartNextBlind ->
            if blindLevelsHasNext model.blindLevels then
                let
                    advancedModel =
                        advanceToNextBlind model
                in
                ( { advancedModel | timerState = Running }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        BuyInPlayerSelected maybePlayer ->
            ( { model | selectedPlayerForBuyIn = maybePlayer }, Cmd.none )

        BuyInDurationChanged str ->
            if model.buyInTimerState == Stopped then
                case String.toInt str of
                    Just minutes ->
                        if minutes > 0 then
                            let
                                durationInSeconds =
                                    minutes * 60
                            in
                            ( { model
                                | buyInTimerDurationInput = str
                                , buyInTimerDuration = durationInSeconds
                                , buyInRemainingTime = durationInSeconds
                              }
                            , Cmd.none
                            )

                        else
                            ( { model | buyInTimerDurationInput = str }, Cmd.none )

                    Nothing ->
                        ( { model | buyInTimerDurationInput = str }, Cmd.none )

            else
                ( model, Cmd.none )

        AddBuyIn ->
            if canAddBuyIn model then
                case model.selectedPlayerForBuyIn of
                    Just player ->
                        ( { model
                            | buyIns = model.buyIns ++ [ BuyIn player ]
                            , selectedPlayerForBuyIn = Nothing
                          }
                        , Cmd.none
                        )

                    Nothing ->
                        ( model, Cmd.none )

            else
                ( model, Cmd.none )

        RemoveBuyIn index ->
            let
                updatedBuyIns =
                    model.buyIns
                        |> List.indexedMap Tuple.pair
                        |> List.filter (\( i, _ ) -> i /= index)
                        |> List.map Tuple.second
            in
            ( { model | buyIns = updatedBuyIns }, Cmd.none )

        BuyInTimerTick _ ->
            if model.buyInTimerState == Running then
                if model.buyInRemainingTime > 0 then
                    ( { model | buyInRemainingTime = model.buyInRemainingTime - 1 }
                    , Cmd.none
                    )

                else
                    ( { model | buyInTimerState = Expired }, Cmd.none )

            else
                ( model, Cmd.none )

        StartPauseBuyInTimer ->
            case model.buyInTimerState of
                Stopped ->
                    ( { model | buyInTimerState = Running }, Cmd.none )

                Paused ->
                    ( { model | buyInTimerState = Running }, Cmd.none )

                Running ->
                    ( { model | buyInTimerState = Paused }, Cmd.none )

                Expired ->
                    ( model, Cmd.none )

        ResetBuyInTimer ->
            ( { model
                | buyInRemainingTime = model.buyInTimerDuration
                , buyInTimerState = Stopped
                , buyInTimerDurationInput = String.fromInt (model.buyInTimerDuration // 60)
              }
            , Cmd.none
            )

        ToggleBuyInList ->
            ( { model | buyInListCollapsed = not model.buyInListCollapsed }, Cmd.none )


advanceToNextBlind : Model -> Model
advanceToNextBlind model =
    if blindLevelsHasNext model.blindLevels then
        { model
            | blindLevels = advanceBlindLevels model.blindLevels
            , remainingTime = model.blindDuration
        }

    else
        { model | remainingTime = 0 }



-- VIEW


view : Model -> Theme -> Element.Element Msg
view model theme =
    let
        colors =
            Theme.getColors theme

        tableSize =
            800.0

        cardSize =
            50.0
    in
    Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.padding 20
        , Element.Font.color colors.text
        ]
        [ Element.el
            [ Element.width Element.fill
            , Element.height Element.fill
            , Element.inFront
                (Element.el
                    [ Element.width Element.shrink
                    , Element.alignTop
                    , Element.paddingEach { top = 30, right = 0, bottom = 0, left = 0 }
                    ]
                    (viewBlindsSection model theme colors)
                )
            , Element.inFront
                (Element.el
                    [ Element.width Element.shrink
                    , Element.alignTop
                    , Element.alignRight
                    , Element.paddingEach { top = 30, right = 20, bottom = 0, left = 0 }
                    ]
                    (PokerHandRanking.view cardSize colors model.activeRankingIndex)
                )
            , Element.inFront
                (Element.el
                    [ Element.width Element.shrink
                    , Element.alignTop
                    , Element.moveDown 550
                    , Element.paddingEach { top = 0, right = 0, bottom = 0, left = 10 }
                    ]
                    (viewBuyInSection model theme colors)
                )
            ]
            (Element.column
                [ Element.width Element.fill
                , Element.height Element.fill
                , Element.spacing 20
                , Element.centerX
                ]
                [ Element.el
                    [ Element.width Element.fill
                    , Element.height Element.fill
                    , Element.centerX
                    , Element.centerY
                    ]
                    (Element.el
                        [ Element.width (Element.px (round tableSize))
                        , Element.height (Element.px (round tableSize))
                        , Element.centerX
                        , Element.inFront
                            (Element.el
                                [ Element.width Element.fill
                                , Element.height Element.fill
                                , Element.centerX
                                , Element.centerY
                                ]
                                (viewPriceMoney (calculateTotalPot model.players model.initialBuyIn model.buyIns) colors)
                            )
                        , Element.inFront
                            (Element.el
                                [ Element.width Element.fill
                                , Element.height Element.fill
                                , Element.centerX
                                , Element.centerY
                                ]
                                (viewCenterBlinds model theme colors)
                            )
                        , Element.inFront
                            (Element.el
                                [ Element.width Element.fill
                                , Element.alignBottom
                                ]
                                (viewChips model.chips colors)
                            )
                        ]
                        (viewPokerTable colors)
                    )
                ]
            )
        , Element.el
            [ Element.width Element.fill
            , Element.Background.color colors.surface
            ]
            (viewFooterMarquee colors)
        ]


viewBlindsSection : Model -> Theme -> Theme.ColorPalette -> Element.Element Msg
viewBlindsSection model theme colors =
    Element.el
        [ Element.width Element.shrink
        , Element.padding 20
        , Element.alignTop
        ]
        (viewLeftControls model theme colors)


viewLeftControls : Model -> Theme -> Theme.ColorPalette -> Element.Element Msg
viewLeftControls model theme colors =
    let
        isInputDisabled =
            model.timerState /= Stopped

        progress =
            if model.blindDuration > 0 then
                toFloat model.remainingTime / toFloat model.blindDuration

            else
                0.0

        timerSize =
            250.0

        timerFaceColor =
            getTimerBackgroundColor theme colors

        timerArmColor =
            colors.primary

        timerDurationMinutes =
            toFloat model.blindDuration / 60.0

        controlButtons =
            case model.timerState of
                Expired ->
                    viewBlinkingStartNextBlindButton model colors

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
                                    (case model.timerState of
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
        [ -- Timer controls and timer icon
          Element.wrappedRow
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
                        , text = model.blindDurationInput
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
        , -- Manual blind advance buttons
          viewManualBlindsAdvance model colors
        , -- Upcoming levels
          viewRightLevels model
        ]


viewCenterBlinds : Model -> Theme -> Theme.ColorPalette -> Element.Element Msg
viewCenterBlinds model theme colors =
    let
        blind =
            getCurrentBlind model

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


viewManualBlindsAdvance : Model -> Theme.ColorPalette -> Element.Element Msg
viewManualBlindsAdvance model colors =
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
                    if blindLevelsHasNext model.blindLevels then
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
                    if blindLevelsHasPrevious model.blindLevels then
                        Just BlindIndexDown

                    else
                        Nothing
                , label = Element.text "↓"
                }
            ]
        ]


viewBlinkingStartNextBlindButton : Model -> Theme.ColorPalette -> Element.Element Msg
viewBlinkingStartNextBlindButton model colors =
    let
        canAdvance =
            blindLevelsHasNext model.blindLevels

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


viewRightLevels : Model -> Element.Element Msg
viewRightLevels model =
    let
        upcomingBlindsList =
            getUpcomingBlinds model

        currentLevelNumberIndex =
            currentBlindNumber model.blindLevels
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
                                    ++ formatBlindValue upcomingBlind.smallBlind
                                    ++ " / "
                                    ++ formatBlindValue upcomingBlind.bigBlind
                                )
                            )
                    )
                    upcomingBlindsList
                )
            ]
        ]


viewChips : List Chip -> Theme.ColorPalette -> Element.Element Msg
viewChips chips colors =
    Element.el
        [ Element.width Element.fill
        , Element.centerX
        ]
        (Element.row
            [ Element.spacing 20
            , Element.centerX
            ]
            (List.map (\chip -> viewChip chip colors) chips)
        )


viewChip : Chip -> Theme.ColorPalette -> Element.Element Msg
viewChip chip colors =
    let
        ( chipColor, value ) =
            case chip of
                Chip color val ->
                    ( color, val )

        chipElementColor =
            chipColorToElementColor chipColor colors

        chipSize =
            150.0

        spinSpeed =
            3.0

        textColor =
            getChipTextColor chipColor colors
    in
    Element.html
        (Icons.pokerChip
            { size = chipSize
            , color = chipElementColor
            , spinSpeed = spinSpeed
            , value = Just value
            , textColor = textColor
            }
        )


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


viewBuyInSection : Model -> Theme -> Theme.ColorPalette -> Element.Element Msg
viewBuyInSection model _ colors =
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
        , viewBuyInTimerControls model colors
        , viewBuyInPlayerSelector model colors
        , viewBuyInList model colors
        ]


viewBuyInTimerControls : Model -> Theme.ColorPalette -> Element.Element Msg
viewBuyInTimerControls model colors =
    let
        isInputDisabled =
            model.buyInTimerState /= Stopped
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
            , text = model.buyInTimerDurationInput
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
                        (case model.buyInTimerState of
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
                (Element.text (formatTime model.buyInRemainingTime))
            ]
        ]


viewBuyInPlayerSelector : Model -> Theme.ColorPalette -> Element.Element Msg
viewBuyInPlayerSelector model colors =
    let
        availablePlayers =
            model.players
                |> List.filter (\player -> not (isPlayerInBuyIns player model.buyIns))

        canAdd =
            canAddBuyIn model

        isSelected : Player -> Bool
        isSelected player =
            case model.selectedPlayerForBuyIn of
                Just selectedPlayer ->
                    selectedPlayer == player

                Nothing ->
                    False

        selectHtml =
            Html.select
                [ Html.Attributes.style "width" "100%"
                , Html.Attributes.style "padding" "8px"
                , Html.Attributes.style "background-color"
                    (if model.buyInTimerState == Expired then
                        "#cccccc"

                     else
                        "transparent"
                    )
                , Html.Attributes.style "color"
                    (if model.buyInTimerState == Expired then
                        "#666666"

                     else
                        "inherit"
                    )
                , Html.Attributes.disabled (model.buyInTimerState == Expired)
                , Html.Events.onInput
                    (\val ->
                        if val == "" then
                            BuyInPlayerSelected Nothing

                        else
                            availablePlayers
                                |> List.filter (\p -> Page.Players.getPlayerName p == val)
                                |> List.head
                                |> Maybe.map (\p -> BuyInPlayerSelected (Just p))
                                |> Maybe.withDefault (BuyInPlayerSelected Nothing)
                    )
                ]
                (Html.option
                    [ Html.Attributes.value ""
                    , Html.Attributes.selected (model.selectedPlayerForBuyIn == Nothing)
                    ]
                    [ Html.text "Select a player..." ]
                    :: List.map
                        (\player ->
                            let
                                playerName =
                                    Page.Players.getPlayerName player
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


viewBuyInList : Model -> Theme.ColorPalette -> Element.Element Msg
viewBuyInList model colors =
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
            , viewBuyInCollapseExpandButton model colors
            ]
        , if List.isEmpty model.buyIns then
            Element.el
                [ Element.Font.color colors.textSecondary
                , Element.Font.italic
                ]
                (Element.text "No buy-ins registered yet.")

          else if model.buyInListCollapsed then
            Element.el
                [ Element.Font.color colors.textSecondary
                , Element.Font.italic
                ]
                (Element.text (String.fromInt (List.length model.buyIns) ++ " buy-ins"))

          else
            Element.column
                [ Element.width Element.fill
                , Element.spacing 8
                ]
                (List.indexedMap (\index buyIn -> viewBuyInRow index buyIn colors) model.buyIns)
        ]


viewBuyInRow : Int -> BuyIn -> Theme.ColorPalette -> Element.Element Msg
viewBuyInRow index buyIn colors =
    let
        player =
            case buyIn of
                BuyIn buyInPlayer ->
                    buyInPlayer

        playerName =
            Page.Players.getPlayerName player
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


viewBuyInCollapseExpandButton : Model -> Theme.ColorPalette -> Element.Element Msg
viewBuyInCollapseExpandButton model colors =
    if not (List.isEmpty model.buyIns) then
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
                        (if model.buyInListCollapsed then
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
                    , "Don’t say what you folded"
                    , "Don’t show your cards before showdown"
                    , "Don’t act before your turn"
                    , "Don’t talk about someone else’s hand"
                    , "Don’t touch other players’ chips or cards"
                    , "Keep your cards on the table while playing"
                    ]
                )
            ]
        )



-- Helper functions


calculateTotalPot : List Player -> Int -> List BuyIn -> Int
calculateTotalPot players buyIn buyIns =
    (List.length players + List.length buyIns) * buyIn


buyInPlayers : List BuyIn -> List Player
buyInPlayers buyIns =
    List.map
        (\buyIn ->
            case buyIn of
                BuyIn player ->
                    player
        )
        buyIns


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


getCurrentBlind : Model -> Blind
getCurrentBlind model =
    blindLevelsCurrent model.blindLevels


getUpcomingBlinds : Model -> List Blind
getUpcomingBlinds model =
    model.blindLevels
        |> upcomingBlinds
        |> List.take 3



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ case model.timerState of
            Running ->
                Time.every 1000 TimerTick

            Paused ->
                Sub.none

            Stopped ->
                Sub.none

            Expired ->
                Sub.none
        , case model.buyInTimerState of
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
