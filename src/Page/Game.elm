module Page.Game exposing (Model, Msg, init, subscriptions, update, view)

import Element
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Icons
import Theme exposing (Theme)
import Time



-- MODEL


type alias Seconds =
    Int


type alias Model =
    { pageName : String
    , chips : List Chip
    , blinds : List Blind
    , currentBlindIndex : Int
    , blindDuration : Seconds
    , remainingTime : Seconds
    , timerState : TimerState
    }


type alias Blind =
    { smallBlind : Int
    , bigBlind : Int
    }


type TimerState
    = Running
    | Paused
    | Stopped


type ChipColor
    = White
    | Red
    | Blue
    | Green
    | Black


type Chip
    = Chip ChipColor Int


init : Model
init =
    { pageName = "Game"
    , chips = [ Chip White 50, Chip Red 100, Chip Blue 200, Chip Green 250, Chip Black 500 ]
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
    , remainingTime = 12 * 60
    , timerState = Stopped
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



-- UPDATE


type Msg
    = NoOp
    | BlindDurationChanged String
    | TimerTick Time.Posix
    | StartPauseTimer
    | ResetTimer
    | BlindIndexUp
    | BlindIndexDown


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
                                | blindDuration = durationInSeconds
                                , remainingTime = durationInSeconds
                              }
                            , Cmd.none
                            )

                        else
                            ( model, Cmd.none )

                    Nothing ->
                        ( model, Cmd.none )

            else
                ( model, Cmd.none )

        TimerTick _ ->
            if model.timerState == Running then
                if model.remainingTime > 0 then
                    ( { model | remainingTime = model.remainingTime - 1 }
                    , Cmd.none
                    )

                else
                    ( advanceToNextBlind model, Cmd.none )

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

        ResetTimer ->
            ( { model
                | currentBlindIndex = 0
                , remainingTime = model.blindDuration
                , timerState = Stopped
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
    in
    Element.el
        [ Element.width Element.fill
        , Element.padding 20
        , Font.color colors.text
        ]
        (Element.column
            [ Element.width Element.fill
            , Element.spacing 20
            ]
            [ Element.text ("Game Content - " ++ model.pageName)
            , viewChips model.chips colors
            , viewBlindsSection model colors
            , viewBlindControls model colors
            ]
        )


viewBlindsSection : Model -> Theme.ColorPalette -> Element.Element Msg
viewBlindsSection model _ =
    let
        currentBlind =
            getCurrentBlind model

        upcomingBlinds =
            getUpcomingBlinds model
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing 15
        ]
        [ Element.el
            [ Font.size 18
            , Font.bold
            ]
            (Element.text "Current Blinds:")
        , case currentBlind of
            Just blind ->
                Element.column
                    [ Element.spacing 5
                    ]
                    [ Element.row
                        [ Element.spacing 10 ]
                        [ Element.text "Small Blind:"
                        , Element.text (formatBlindValue blind.smallBlind)
                        ]
                    , Element.row
                        [ Element.spacing 10 ]
                        [ Element.text "Big Blind:"
                        , Element.text (formatBlindValue blind.bigBlind)
                        ]
                    ]

            Nothing ->
                Element.text "No blind level"
        , Element.el
            [ Font.size 18
            , Font.bold
            , Element.paddingEach { top = 10, bottom = 0, left = 0, right = 0 }
            ]
            (Element.text "Next Blind Level in:")
        , Element.el
            [ Font.size 16 ]
            (Element.text ("[ " ++ formatTime model.remainingTime ++ " remaining ]"))
        , Element.el
            [ Font.size 18
            , Font.bold
            , Element.paddingEach { top = 10, bottom = 0, left = 0, right = 0 }
            ]
            (Element.text "Upcoming Levels:")
        , Element.column
            [ Element.spacing 5 ]
            (List.indexedMap
                (\idx blind ->
                    Element.text
                        ("Level "
                            ++ String.fromInt (model.currentBlindIndex + idx + 2)
                            ++ ":  "
                            ++ formatBlindValue blind.smallBlind
                            ++ " / "
                            ++ formatBlindValue blind.bigBlind
                        )
                )
                upcomingBlinds
            )
        ]


viewBlindControls : Model -> Theme.ColorPalette -> Element.Element Msg
viewBlindControls model colors =
    let
        startPauseText =
            case model.timerState of
                Running ->
                    "Pause"

                Paused ->
                    "Start"

                Stopped ->
                    "Start"

        isInputDisabled =
            model.timerState /= Stopped
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing 15
        ]
        [ Element.row
            [ Element.spacing 10
            , Element.width Element.fill
            ]
            [ Element.el
                [ Element.width (Element.px 150) ]
                (Element.text "Blind Duration:")
            , Input.text
                [ Element.width (Element.px 100)
                , Element.padding 8
                , Background.color colors.surface
                , Font.color colors.text
                , Element.htmlAttribute
                    (if isInputDisabled then
                        Html.Attributes.disabled True

                     else
                        Html.Attributes.disabled False
                    )
                ]
                { onChange = BlindDurationChanged
                , text = String.fromInt (model.blindDuration // 60)
                , placeholder = Nothing
                , label = Input.labelHidden "Blind duration in minutes"
                }
            , Element.text "(min)"
            ]
        , Element.row
            [ Element.spacing 10 ]
            [ Input.button
                [ Element.padding 10
                , Background.color colors.primary
                , Font.color colors.text
                ]
                { onPress = Just StartPauseTimer
                , label = Element.text startPauseText
                }
            , Input.button
                [ Element.padding 10
                , Background.color colors.primary
                , Font.color colors.text
                ]
                { onPress = Just ResetTimer
                , label = Element.text "Reset"
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
            , Input.button
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
            ]
        ]


viewChips : List Chip -> Theme.ColorPalette -> Element.Element Msg
viewChips chips colors =
    Element.row
        [ Element.width Element.fill
        , Element.spacing 20
        , Element.centerX
        ]
        (List.map (\chip -> viewChip chip colors) chips)


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
            120.0

        spinSpeed =
            3.0
    in
    Element.column
        [ Element.spacing 10
        , Element.centerX
        ]
        [ Element.html
            (Icons.pokerChip
                { size = chipSize
                , color = chipElementColor
                , spinSpeed = spinSpeed
                }
            )
        , Element.el
            [ Element.centerX
            , Font.color colors.text
            ]
            (Element.text (String.fromInt value))
        ]



-- Helper functions


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
    case model.timerState of
        Running ->
            Time.every 1000 TimerTick

        Paused ->
            Sub.none

        Stopped ->
            Sub.none
