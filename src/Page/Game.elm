port module Page.Game exposing (Model, Msg, init, subscriptions, update, view)

import Element
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Html.Events
import Icons
import Marquee
import Page.Players exposing (Player)
import PokerHandRanking
import Random
import Theme exposing (Theme)
import Time



-- PORT


port blindTimerAlert : () -> Cmd msg



-- MODEL


type alias Model =
    { chips : List Chip
    , blinds : List Blind
    , currentBlindIndex : Int
    , blindDuration : Seconds
    , blindDurationInput : String
    , remainingTime : Seconds
    , timerState : TimerState
    , players : List Player
    , initialBuyIn : Int
    , activeRankingIndex : Maybe Int
    , buyIns : List BuyIn
    , selectedPlayerForBuyIn : Maybe Int
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
    = BuyIn Int


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
            , blinds =
                [ { smallBlind = 100, bigBlind = 200 }
                , { smallBlind = 200, bigBlind = 400 }
                , { smallBlind = 300, bigBlind = 600 }
                , { smallBlind = 400, bigBlind = 800 }
                , { smallBlind = 500, bigBlind = 1000 }
                , { smallBlind = 800, bigBlind = 1600 }
                , { smallBlind = 1000, bigBlind = 2000 }
                , { smallBlind = 2000, bigBlind = 4000 }
                ]
            , currentBlindIndex = 0
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


chipColorToElementColor : ChipColor -> Element.Color
chipColorToElementColor chipColor =
    case chipColor of
        White ->
            Element.rgb255 255 255 255

        Red ->
            Element.rgb255 220 20 60

        Blue ->
            Element.rgb255 30 144 255

        Green ->
            Element.rgb255 34 139 34

        Black ->
            Element.rgb255 0 0 0


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
            Element.rgb255 180 230 210

        Theme.Dark ->
            colors.surface


getBigBlindBackgroundColor : Theme -> Theme.ColorPalette -> Element.Color
getBigBlindBackgroundColor theme colors =
    case theme of
        Theme.Light ->
            Element.rgb255 220 170 80

        Theme.Dark ->
            colors.surface


getSmallBlindBackgroundColor : Theme -> Theme.ColorPalette -> Element.Color
getSmallBlindBackgroundColor theme colors =
    case theme of
        Theme.Light ->
            Element.rgb255 160 210 255

        Theme.Dark ->
            colors.surface



-- UPDATE


isPlayerInBuyIns : Int -> List BuyIn -> Bool
isPlayerInBuyIns playerIndex buyIns =
    List.any
        (\buyIn ->
            case buyIn of
                BuyIn index ->
                    index == playerIndex
        )
        buyIns


canAddBuyIn : Model -> Bool
canAddBuyIn model =
    model.buyInTimerState
        /= Expired
        && model.selectedPlayerForBuyIn
        /= Nothing
        && (case model.selectedPlayerForBuyIn of
                Just playerIndex ->
                    not (isPlayerInBuyIns playerIndex model.buyIns)

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
    | BuyInPlayerSelected (Maybe Int)
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
                    ( { model | timerState = Expired }, blindTimerAlert () )

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
                | currentBlindIndex = 0
                , remainingTime = model.blindDuration
                , timerState = Stopped
                , blindDurationInput = String.fromInt (model.blindDuration // 60)
              }
            , Cmd.none
            )

        BlindIndexUp ->
            if model.currentBlindIndex < List.length model.blinds - 1 then
                ( { model
                    | currentBlindIndex = model.currentBlindIndex + 1
                    , remainingTime = model.blindDuration
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        BlindIndexDown ->
            if model.currentBlindIndex > 0 then
                ( { model
                    | currentBlindIndex = model.currentBlindIndex - 1
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
            if model.currentBlindIndex < List.length model.blinds - 1 then
                let
                    advancedModel =
                        advanceToNextBlind model
                in
                ( { advancedModel | timerState = Running }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        BuyInPlayerSelected maybeIndex ->
            ( { model | selectedPlayerForBuyIn = maybeIndex }, Cmd.none )

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
                    Just playerIndex ->
                        ( { model
                            | buyIns = model.buyIns ++ [ BuyIn playerIndex ]
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
    if model.currentBlindIndex < List.length model.blinds - 1 then
        { model
            | currentBlindIndex = model.currentBlindIndex + 1
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
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.padding 20
        , Font.color colors.text
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
        , Element.inFront
            (Element.el
                [ Element.width Element.fill
                , Element.alignBottom
                , Element.moveUp -280
                , Background.color colors.surface
                ]
                (viewFooterMarquee colors)
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
                    viewPokerTable
                )
            ]
        )


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
                        [ Input.button
                            [ Element.padding 10
                            , Background.color colors.primary
                            , Font.color colors.text
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
                        , Input.button
                            [ Element.padding 10
                            , Background.color colors.primary
                            , Font.color colors.text
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
                        [ Font.size 16
                        ]
                        (Element.text "Blind Duration:")
                    , Input.text
                        [ Element.width (Element.px 80)
                        , Element.alignLeft
                        , Element.padding 8
                        , Background.color colors.background
                        , Font.color colors.text
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
                        , label = Input.labelHidden "Blind duration in minutes"
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
        currentBlind =
            getCurrentBlind model

        iconSize =
            140.0
    in
    case currentBlind of
        Just blind ->
            Element.row
                [ Element.centerX
                ]
                [ Element.html
                    (Icons.bigBlind
                        { size = iconSize
                        , backgroundColor = getBigBlindBackgroundColor theme colors
                        , labelTextColor = Element.rgb255 255 215 0
                        , valueTextColor = Element.rgb255 255 215 0
                        , value = blind.bigBlind
                        }
                    )
                , Element.html
                    (Icons.smallBlind
                        { size = iconSize
                        , backgroundColor = getSmallBlindBackgroundColor theme colors
                        , labelTextColor = Element.rgb255 30 144 255
                        , valueTextColor = Element.rgb255 30 144 255
                        , value = blind.smallBlind
                        }
                    )
                ]

        Nothing ->
            Element.text "No blind level"


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
            [ Input.button
                [ Element.padding 10
                , Background.color colors.primary
                , Font.color colors.text
                ]
                { onPress =
                    if model.currentBlindIndex < List.length model.blinds - 1 then
                        Just BlindIndexUp

                    else
                        Nothing
                , label = Element.text "↑"
                }
            , Input.button
                [ Element.padding 10
                , Background.color colors.primary
                , Font.color colors.text
                ]
                { onPress =
                    if model.currentBlindIndex > 0 then
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
            model.currentBlindIndex < List.length model.blinds - 1

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
        , Input.button
            [ Element.padding 10
            , Background.color colors.primary
            , Font.color colors.text
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
        upcomingBlinds =
            getUpcomingBlinds model
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
                [ Font.size 14
                , Font.bold
                ]
                (Element.text "Upcoming Levels:")
            , Element.column
                [ Element.spacing 5 ]
                (List.indexedMap
                    (\idx upcomingBlind ->
                        Element.el
                            [ Font.size 18
                            , Font.bold
                            , Font.family [ Font.monospace ]
                            , Element.width Element.fill
                            ]
                            (Element.text
                                ("Level "
                                    ++ String.fromInt (model.currentBlindIndex + idx + 2)
                                    ++ ":  "
                                    ++ formatBlindValue upcomingBlind.smallBlind
                                    ++ " / "
                                    ++ formatBlindValue upcomingBlind.bigBlind
                                )
                            )
                    )
                    upcomingBlinds
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
            chipColorToElementColor chipColor

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


viewPokerTable : Element.Element Msg
viewPokerTable =
    let
        tableColor =
            Element.rgb255 10 143 60

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
            Element.rgb255 255 215 0
    in
    Element.row
        [ Element.centerX
        , Element.centerY
        ]
        [ Element.el
            [ Font.size 48
            , Font.bold
            , Font.color colors.text
            , Font.family [ Font.monospace ]
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
            [ Font.size 16
            , Font.bold
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
            [ Font.size 14
            ]
            (Element.text "Buy-In Timer Duration:")
        , Input.text
            [ Element.width (Element.px 80)
            , Element.alignLeft
            , Element.padding 8
            , Background.color colors.background
            , Font.color colors.text
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
            , label = Input.labelHidden "Buy-in timer duration in minutes"
            }
        , Element.row
            [ Element.spacing 10
            , Element.alignLeft
            ]
            [ Input.button
                [ Element.padding 10
                , Background.color colors.primary
                , Font.color colors.text
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
            , Input.button
                [ Element.padding 10
                , Background.color colors.primary
                , Font.color colors.text
                ]
                { onPress = Just ResetBuyInTimer
                , label = Element.text "Reset"
                }
            , Element.el
                [ Font.size 24
                , Font.bold
                , Font.family [ Font.monospace ]
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
                |> List.indexedMap Tuple.pair
                |> List.filter (\( index, _ ) -> not (isPlayerInBuyIns index model.buyIns))

        canAdd =
            canAddBuyIn model

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
                            case String.toInt val of
                                Just idx ->
                                    BuyInPlayerSelected (Just idx)

                                Nothing ->
                                    BuyInPlayerSelected Nothing
                    )
                ]
                (Html.option
                    [ Html.Attributes.value ""
                    , Html.Attributes.selected (model.selectedPlayerForBuyIn == Nothing)
                    ]
                    [ Html.text "Select a player..." ]
                    :: List.map
                        (\( index, player ) ->
                            let
                                playerName =
                                    Page.Players.getPlayerName player
                            in
                            Html.option
                                [ Html.Attributes.value (String.fromInt index)
                                , Html.Attributes.selected (model.selectedPlayerForBuyIn == Just index)
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
        , Input.button
            [ Element.padding 8
            , Element.width (Element.fillPortion 1)
            , Background.color
                (if canAdd then
                    colors.primary

                 else
                    colors.surface
                )
            , Font.color
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
                [ Font.size 16
                , Font.bold
                ]
                (Element.text "Registered Buy-Ins:")
            , viewBuyInCollapseExpandButton model colors
            ]
        , if List.isEmpty model.buyIns then
            Element.el
                [ Font.color colors.textSecondary
                , Font.italic
                ]
                (Element.text "No buy-ins registered yet.")

          else if model.buyInListCollapsed then
            Element.el
                [ Font.color colors.textSecondary
                , Font.italic
                ]
                (Element.text (String.fromInt (List.length model.buyIns) ++ " buy-ins"))

          else
            Element.column
                [ Element.width Element.fill
                , Element.spacing 8
                ]
                (List.indexedMap (\index buyIn -> viewBuyInRow index buyIn model.players colors) model.buyIns)
        ]


viewBuyInRow : Int -> BuyIn -> List Player -> Theme.ColorPalette -> Element.Element Msg
viewBuyInRow index buyIn players colors =
    let
        playerIndex =
            case buyIn of
                BuyIn idx ->
                    idx

        playerName =
            players
                |> List.drop playerIndex
                |> List.head
                |> Maybe.map Page.Players.getPlayerName
                |> Maybe.withDefault "Unknown Player"
    in
    Element.row
        [ Element.width Element.fill
        , Element.spacing 10
        ]
        [ Element.el
            [ Element.width Element.fill
            ]
            (Element.text ("- " ++ playerName))
        , Input.button
            [ Element.padding 8
            , Background.color colors.accent
            , Font.color colors.text
            ]
            { onPress = Just (RemoveBuyIn index)
            , label = Element.text "Remove"
            }
        ]


viewBuyInCollapseExpandButton : Model -> Theme.ColorPalette -> Element.Element Msg
viewBuyInCollapseExpandButton model colors =
    if not (List.isEmpty model.buyIns) then
        Input.button
            [ Element.padding 4
            , Element.width (Element.px 40)
            , Element.height (Element.px 40)
            , Background.color colors.primary
            , Font.color colors.text
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
    Marquee.view
        [ "Don't talk about your hand while cards are still being dealt"
        , "Never reveal your folded cards"
        , "Don't discuss ongoing hands"
        , "Don't slow roll — show your winning hand quickly"
        , "Don't soft-play friends — always play competitively"
        , "Act only when it's your turn"
        , "Announce your action clearly: call, raise, or fold"
        , "A raise must be one smooth motion"
        , "Chips placed in silently count as a call"
        , "Minimum raise must match the previous full raise"
        , "Only chips on the table count"
        , "Show both hole cards to win the pot at showdown"
        , "Blinds rotate clockwise each hand"
        ]



-- Helper functions


calculateTotalPot : List Player -> Int -> List BuyIn -> Int
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


getCurrentBlind : Model -> Maybe Blind
getCurrentBlind model =
    model.blinds
        |> List.drop model.currentBlindIndex
        |> List.head


getUpcomingBlinds : Model -> List Blind
getUpcomingBlinds model =
    model.blinds
        |> List.drop (model.currentBlindIndex + 1)
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
