module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Element
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Page.Champion
import Page.Game
import Page.Home
import Page.Players
import Page.Playground
import Page.Settings
import Player exposing (Player(..))
import Ports
import Random
import Theme exposing (Theme(..))
import Url exposing (Url)
import Url.Parser exposing (Parser, s, top)



-- MODEL


type alias ChipSetting =
    { color : Page.Game.ChipColor
    , value : Int
    , valueInput : String
    , enabled : Bool
    }


type alias AppSettings =
    { chipSettings : List ChipSetting
    , blindLevelSettings : List Page.Settings.BlindLevelSetting
    }


type alias Model =
    { navigationKey : Navigation.Key
    , activePage : Page
    , theme : Theme
    , settings : AppSettings

    -- Players
    , players : List Page.Players.PlayerEntry
    , initialBuyIn : Int
    , newPlayerName : String
    , playerListCollapsed : Bool

    -- Game
    , blindLevels : Page.Game.BlindLevels
    , blindDuration : Page.Game.Seconds
    , blindDurationInput : String
    , remainingTime : Page.Game.Seconds
    , timerState : Page.Game.TimerState
    , activeRankingIndex : Maybe Int
    , selectedPlayerForBuyIn : Maybe Player
    , buyIns : List Player
    , buyInTimerDuration : Page.Game.Seconds
    , buyInTimerDurationInput : String
    , buyInRemainingTime : Page.Game.Seconds
    , buyInTimerState : Page.Game.TimerState
    , buyInListCollapsed : Bool

    -- Champion
    , winnerFlow : Page.Champion.WinnerFlow
    }


type Page
    = HomePage
    | PlayersPage
    | GamePage
    | ChampionPage
    | PlaygroundPage
    | SettingsPage
    | NotFoundPage


type Route
    = Home
    | Players
    | Game
    | Champion
    | Playground
    | Settings



-- UPDATE


type Msg
    = ClickedLink Browser.UrlRequest
    | ChangedUrl Url
    | GotPlayersIntent Page.Players.Intent
    | GotGameIntent Page.Game.Intent
    | GotChampionIntent Page.Champion.Intent
    | GotSettingsIntent Page.Settings.Intent
    | ThemeToggled
    | PortsMsg Ports.Incoming


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink urlRequest ->
            case urlRequest of
                Browser.External href ->
                    ( model, Navigation.load href )

                Browser.Internal url ->
                    ( model, Navigation.pushUrl model.navigationKey (Url.toString url) )

        ChangedUrl url ->
            updateUrl url model

        GotPlayersIntent playersIntent ->
            case model.activePage of
                PlayersPage ->
                    updatePlayers playersIntent model

                _ ->
                    ( model, Cmd.none )

        GotGameIntent gameIntent ->
            case model.activePage of
                GamePage ->
                    updateGame gameIntent model

                _ ->
                    ( model, Cmd.none )

        GotChampionIntent championIntent ->
            case model.activePage of
                ChampionPage ->
                    updateChampion championIntent model

                _ ->
                    ( model, Cmd.none )

        GotSettingsIntent settingsIntent ->
            case model.activePage of
                SettingsPage ->
                    updateSettings settingsIntent model

                _ ->
                    ( model, Cmd.none )

        ThemeToggled ->
            ( { model
                | theme =
                    case model.theme of
                        Light ->
                            Dark

                        Dark ->
                            Light
              }
            , Cmd.none
            )

        PortsMsg incoming ->
            case incoming of
                Ports.IncomingNoOp ->
                    ( model, Cmd.none )


updateUrl : Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Url.Parser.parse routeParser url of
        Just Home ->
            ( { model | activePage = HomePage }, Cmd.none )

        Just Players ->
            ( { model | activePage = PlayersPage }, Cmd.none )

        Just Game ->
            ( { model | activePage = GamePage }, Cmd.none )

        Just Champion ->
            ( { model | activePage = ChampionPage }
            , Cmd.none
            )

        Just Playground ->
            ( { model | activePage = PlaygroundPage }, Cmd.none )

        Just Settings ->
            ( { model | activePage = SettingsPage }, Cmd.none )

        Nothing ->
            ( { model | activePage = NotFoundPage }, Cmd.none )


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        initialBlindDuration =
            12 * 60

        initialBuyInTimerDuration =
            30 * 60

        initialModel =
            { navigationKey = key
            , activePage = NotFoundPage
            , theme = Theme.defaultTheme
            , settings =
                { chipSettings =
                    [ { color = Page.Game.White, value = 50, valueInput = "50", enabled = True }
                    , { color = Page.Game.Red, value = 100, valueInput = "100", enabled = True }
                    , { color = Page.Game.Blue, value = 200, valueInput = "200", enabled = True }
                    , { color = Page.Game.Green, value = 250, valueInput = "250", enabled = True }
                    , { color = Page.Game.Black, value = 500, valueInput = "500", enabled = True }
                    ]
                , blindLevelSettings = defaultBlindLevelSettings
                }

            -- Players
            , players = []
            , initialBuyIn = 0
            , newPlayerName = ""
            , playerListCollapsed = False

            -- Game
            , blindLevels = blindLevelsFromSettings defaultBlindLevelSettings
            , blindDuration = initialBlindDuration
            , blindDurationInput = "12"
            , remainingTime = initialBlindDuration
            , timerState = Page.Game.Stopped
            , activeRankingIndex = Just 0
            , selectedPlayerForBuyIn = Nothing
            , buyIns = []
            , buyInTimerDuration = initialBuyInTimerDuration
            , buyInTimerDurationInput = "30"
            , buyInRemainingTime = initialBuyInTimerDuration
            , buyInTimerState = Page.Game.Stopped
            , buyInListCollapsed = True

            -- Champion
            , winnerFlow = Page.Champion.AwaitingDivision
            }
    in
    updateUrl url initialModel



-- UPDATE: PLAYERS


updatePlayers : Page.Players.Intent -> Model -> ( Model, Cmd Msg )
updatePlayers intent model =
    case intent of
        Page.Players.PlayerNameChanged name ->
            ( { model | newPlayerName = name }, Cmd.none )

        Page.Players.InitialBuyInChanged buyInStr ->
            case String.toInt buyInStr of
                Just buyIn ->
                    ( { model | initialBuyIn = buyIn }, Cmd.none )

                Nothing ->
                    ( { model | initialBuyIn = 0 }, Cmd.none )

        Page.Players.AddPlayer ->
            let
                trimmedName =
                    String.trim model.newPlayerName

                isUnique =
                    not (List.any (\entry -> Player.getName entry.player == trimmedName) model.players)
            in
            if trimmedName /= "" && isUnique then
                let
                    newEntry =
                        { player = Player trimmedName
                        , seat = Nothing
                        }
                in
                ( { model
                    | players = model.players ++ [ newEntry ]
                    , newPlayerName = ""
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Page.Players.RemovePlayer index ->
            let
                removedPlayer =
                    model.players
                        |> List.drop index
                        |> List.head
                        |> Maybe.map .player

                updatedPlayers =
                    model.players
                        |> List.indexedMap Tuple.pair
                        |> List.filter (\( i, _ ) -> i /= index)
                        |> List.map Tuple.second

                updatedBuyIns =
                    case removedPlayer of
                        Just player ->
                            List.filter (\p -> p /= player) model.buyIns

                        Nothing ->
                            model.buyIns

                currentRoster =
                    List.map .player updatedPlayers

                updatedWinnerFlow =
                    cleanupWinnerFlow currentRoster model.winnerFlow
            in
            ( { model
                | players = updatedPlayers
                , buyIns = updatedBuyIns
                , winnerFlow = updatedWinnerFlow
              }
            , Cmd.none
            )

        Page.Players.RandomizeSeating ->
            if List.isEmpty model.players || Page.Players.hasSeatingEntries model.players then
                ( model, Cmd.none )

            else
                ( model
                , Random.generate (\seed -> GotPlayersIntent (Page.Players.GotRandomSeed seed)) (Random.int 0 2147483647)
                )

        Page.Players.GotRandomSeed seed ->
            let
                currentRoster =
                    List.map .player model.players

                shuffledPlayers =
                    Page.Players.shufflePlayers seed currentRoster

                tables =
                    Page.Players.distributeIntoTables shuffledPlayers

                assignments =
                    Page.Players.seatsFromTables tables

                updatedPlayers =
                    Page.Players.assignSeats model.players assignments
            in
            ( { model
                | players = updatedPlayers
                , playerListCollapsed = True
              }
            , Cmd.none
            )

        Page.Players.TogglePlayerList ->
            ( { model | playerListCollapsed = not model.playerListCollapsed }, Cmd.none )

        Page.Players.ClearSeating ->
            ( { model
                | players = Page.Players.clearSeats model.players
                , playerListCollapsed = False
              }
            , Cmd.none
            )


cleanupWinnerFlow : List Player -> Page.Champion.WinnerFlow -> Page.Champion.WinnerFlow
cleanupWinnerFlow currentRoster winnerFlow =
    case winnerFlow of
        Page.Champion.AwaitingDivision ->
            winnerFlow

        Page.Champion.DivisionSelected selection ->
            let
                updatedWinners =
                    selection.winners
                        |> List.filter (\winner -> List.member winner.player currentRoster)
                        |> List.indexedMap (\idx winner -> { winner | position = idx + 1 })
            in
            Page.Champion.DivisionSelected { selection | winners = updatedWinners }



-- UPDATE: GAME


updateGame : Page.Game.Intent -> Model -> ( Model, Cmd Msg )
updateGame intent model =
    case intent of
        Page.Game.NoOp ->
            ( model, Cmd.none )

        Page.Game.BlindDurationChanged str ->
            if model.timerState == Page.Game.Stopped then
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

        Page.Game.TimerTick _ ->
            if model.timerState == Page.Game.Running then
                if model.remainingTime > 0 then
                    ( { model | remainingTime = model.remainingTime - 1 }
                    , Cmd.none
                    )

                else
                    ( { model | timerState = Page.Game.Expired }, Ports.send Ports.BlindTimerAlert )

            else
                ( model, Cmd.none )

        Page.Game.StartPauseTimer ->
            case model.timerState of
                Page.Game.Stopped ->
                    ( { model | timerState = Page.Game.Running }, Cmd.none )

                Page.Game.Paused ->
                    ( { model | timerState = Page.Game.Running }, Cmd.none )

                Page.Game.Running ->
                    ( { model | timerState = Page.Game.Paused }, Cmd.none )

                Page.Game.Expired ->
                    ( model, Cmd.none )

        Page.Game.ResetTimer ->
            ( { model
                | blindLevels = blindLevelsFromSettings model.settings.blindLevelSettings
                , remainingTime = model.blindDuration
                , timerState = Page.Game.Stopped
                , blindDurationInput = String.fromInt (model.blindDuration // 60)
              }
            , Cmd.none
            )

        Page.Game.BlindIndexUp ->
            if Page.Game.blindLevelsHasNext model.blindLevels then
                ( { model
                    | blindLevels = Page.Game.advanceBlindLevels model.blindLevels
                    , remainingTime = model.blindDuration
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Page.Game.BlindIndexDown ->
            if Page.Game.blindLevelsHasPrevious model.blindLevels then
                ( { model
                    | blindLevels = Page.Game.rewindBlindLevels model.blindLevels
                    , remainingTime = model.blindDuration
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Page.Game.RankingTimerTick _ ->
            ( model, Cmd.map GotGameIntent (Random.generate Page.Game.GenerateRandomRanking (Random.int 0 9)) )

        Page.Game.GenerateRandomRanking index ->
            ( { model | activeRankingIndex = Just index }, Cmd.none )

        Page.Game.StartNextBlind ->
            if Page.Game.blindLevelsHasNext model.blindLevels then
                ( { model
                    | blindLevels = Page.Game.advanceBlindLevels model.blindLevels
                    , remainingTime = model.blindDuration
                    , timerState = Page.Game.Running
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Page.Game.BuyInPlayerSelected maybePlayer ->
            ( { model | selectedPlayerForBuyIn = maybePlayer }, Cmd.none )

        Page.Game.BuyInDurationChanged str ->
            if model.buyInTimerState == Page.Game.Stopped then
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

        Page.Game.AddBuyIn ->
            let
                vd =
                    gameViewData model
            in
            if Page.Game.canAddBuyIn vd then
                case model.selectedPlayerForBuyIn of
                    Just player ->
                        ( { model
                            | selectedPlayerForBuyIn = Nothing
                            , buyIns = model.buyIns ++ [ player ]
                          }
                        , Cmd.none
                        )

                    Nothing ->
                        ( model, Cmd.none )

            else
                ( model, Cmd.none )

        Page.Game.RemoveBuyIn index ->
            if index >= 0 && index < List.length model.buyIns then
                ( { model
                    | buyIns =
                        model.buyIns
                            |> List.indexedMap Tuple.pair
                            |> List.filter (\( i, _ ) -> i /= index)
                            |> List.map Tuple.second
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Page.Game.BuyInTimerTick _ ->
            if model.buyInTimerState == Page.Game.Running then
                if model.buyInRemainingTime > 0 then
                    ( { model | buyInRemainingTime = model.buyInRemainingTime - 1 }
                    , Cmd.none
                    )

                else
                    ( { model | buyInTimerState = Page.Game.Expired }, Cmd.none )

            else
                ( model, Cmd.none )

        Page.Game.StartPauseBuyInTimer ->
            case model.buyInTimerState of
                Page.Game.Stopped ->
                    ( { model | buyInTimerState = Page.Game.Running }, Cmd.none )

                Page.Game.Paused ->
                    ( { model | buyInTimerState = Page.Game.Running }, Cmd.none )

                Page.Game.Running ->
                    ( { model | buyInTimerState = Page.Game.Paused }, Cmd.none )

                Page.Game.Expired ->
                    ( model, Cmd.none )

        Page.Game.ResetBuyInTimer ->
            ( { model
                | buyInRemainingTime = model.buyInTimerDuration
                , buyInTimerState = Page.Game.Stopped
                , buyInTimerDurationInput = String.fromInt (model.buyInTimerDuration // 60)
              }
            , Cmd.none
            )

        Page.Game.ToggleBuyInList ->
            ( { model | buyInListCollapsed = not model.buyInListCollapsed }, Cmd.none )



-- UPDATE: CHAMPION


updateChampion : Page.Champion.Intent -> Model -> ( Model, Cmd Msg )
updateChampion intent model =
    let
        winnerFlow =
            model.winnerFlow

        updatedWinnerFlow =
            case intent of
                Page.Champion.PotDivisionSelected division ->
                    Page.Champion.selectDivision division winnerFlow

                Page.Champion.WinnerSelected player position ->
                    case winnerFlow of
                        Page.Champion.DivisionSelected selection ->
                            if Page.Champion.canAddWinner selection player position then
                                Page.Champion.DivisionSelected (Page.Champion.addWinner selection player position)

                            else
                                winnerFlow

                        Page.Champion.AwaitingDivision ->
                            winnerFlow

                Page.Champion.WinnerRemoved player ->
                    case winnerFlow of
                        Page.Champion.DivisionSelected selection ->
                            Page.Champion.DivisionSelected (Page.Champion.removeWinner selection player)

                        Page.Champion.AwaitingDivision ->
                            winnerFlow

                Page.Champion.PhoneNumberChanged player phoneNumber ->
                    case winnerFlow of
                        Page.Champion.DivisionSelected selection ->
                            Page.Champion.DivisionSelected
                                { selection
                                    | winners =
                                        List.map
                                            (\winner ->
                                                if winner.player == player then
                                                    { winner | phoneNumber = phoneNumber }

                                                else
                                                    winner
                                            )
                                            selection.winners
                                }

                        Page.Champion.AwaitingDivision ->
                            winnerFlow

                Page.Champion.ClearWinners ->
                    case winnerFlow of
                        Page.Champion.DivisionSelected selection ->
                            Page.Champion.DivisionSelected { selection | winners = [] }

                        Page.Champion.AwaitingDivision ->
                            winnerFlow
    in
    ( { model | winnerFlow = updatedWinnerFlow }
    , Cmd.none
    )



-- UPDATE: SETTINGS


updateSettings : Page.Settings.Intent -> Model -> ( Model, Cmd Msg )
updateSettings intent model =
    let
        settings =
            model.settings

        chipSettings =
            settings.chipSettings
    in
    case intent of
        Page.Settings.ChipToggled targetColor ->
            let
                updatedChipSettings =
                    List.map
                        (\cs ->
                            if cs.color == targetColor then
                                { cs | enabled = not cs.enabled }

                            else
                                cs
                        )
                        chipSettings
            in
            ( { model | settings = { settings | chipSettings = updatedChipSettings } }
            , Cmd.none
            )

        Page.Settings.ChipValueChanged targetColor str ->
            let
                updatedChipSettings =
                    List.map
                        (\cs ->
                            if cs.color == targetColor then
                                case String.toInt str of
                                    Just v ->
                                        { cs | valueInput = str, value = v }

                                    Nothing ->
                                        { cs | valueInput = str }

                            else
                                cs
                        )
                        chipSettings
            in
            ( { model | settings = { settings | chipSettings = updatedChipSettings } }
            , Cmd.none
            )

        Page.Settings.BlindSmallChanged targetIndex str ->
            let
                updatedBlindSettings =
                    List.indexedMap
                        (\i bl ->
                            if i == targetIndex then
                                case String.toInt str of
                                    Just v ->
                                        { bl | smallBlindInput = str, smallBlind = v }

                                    Nothing ->
                                        { bl | smallBlindInput = str }

                            else
                                bl
                        )
                        settings.blindLevelSettings
            in
            ( { model
                | settings = { settings | blindLevelSettings = updatedBlindSettings }
                , blindLevels = blindLevelsFromSettings updatedBlindSettings
              }
            , Cmd.none
            )

        Page.Settings.BlindBigChanged targetIndex str ->
            let
                updatedBlindSettings =
                    List.indexedMap
                        (\i bl ->
                            if i == targetIndex then
                                case String.toInt str of
                                    Just v ->
                                        { bl | bigBlindInput = str, bigBlind = v }

                                    Nothing ->
                                        { bl | bigBlindInput = str }

                            else
                                bl
                        )
                        settings.blindLevelSettings
            in
            ( { model
                | settings = { settings | blindLevelSettings = updatedBlindSettings }
                , blindLevels = blindLevelsFromSettings updatedBlindSettings
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        pageSubscriptions =
            case model.activePage of
                GamePage ->
                    Sub.map GotGameIntent (Page.Game.subscriptions (gameViewData model))

                _ ->
                    Sub.none
    in
    Sub.batch
        [ pageSubscriptions
        , Ports.subscriptions PortsMsg
        ]



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        colors =
            Theme.getColors model.theme
    in
    { title = "PokerNight App"
    , body =
        [ Html.node "style"
            []
            [ Html.text ("html, body { background-color: " ++ themeBackgroundCss model.theme ++ "; }")
            ]
        , Element.layout
            [ Background.color colors.background
            ]
            (Element.column
                [ Element.width Element.fill
                , Element.spacing 0
                ]
                [ -- Title row with navigation
                  Element.row
                    [ Element.width Element.fill
                    , Element.padding 20
                    , Element.spacing 15
                    ]
                    [ Element.el
                        [ Font.color colors.text
                        ]
                        (Element.text "PokerNight App")
                    , viewNavigation colors model.activePage
                    , Element.el
                        [ Element.alignRight
                        ]
                        (viewThemeToggle model.theme)
                    ]

                -- Content area
                , viewPageContent model
                ]
            )
        ]
    }


viewNavigation : Theme.ColorPalette -> Page -> Element.Element Msg
viewNavigation colors activePage =
    Element.row
        [ Element.spacing 15
        ]
        [ navButton colors Home activePage
        , navButton colors Players activePage
        , navButton colors Game activePage
        , navButton colors Champion activePage
        , navButton colors Settings activePage
        ]


navButton : Theme.ColorPalette -> Route -> Page -> Element.Element Msg
navButton colors route activePage =
    let
        active =
            isActive { link = route, activePage = activePage }

        attributes =
            [ Element.padding 10
            , Element.spacing 5
            , Background.color colors.primary
            , Font.color colors.buttonText
            ]
                ++ (if active then
                        [ Font.underline ]

                    else
                        []
                   )
    in
    Element.link
        attributes
        { url = routeToPath route
        , label = Element.text ("[ " ++ routeToString route ++ " ]")
        }


viewPageContent : Model -> Element.Element Msg
viewPageContent model =
    case model.activePage of
        HomePage ->
            Page.Home.view model.theme

        PlayersPage ->
            Page.Players.view
                (playersViewData model)
                model.theme
                |> Element.map GotPlayersIntent

        GamePage ->
            Page.Game.view
                (gameViewData model)
                model.theme
                |> Element.map GotGameIntent

        ChampionPage ->
            Page.Champion.view
                (championViewData model)
                model.theme
                |> Element.map GotChampionIntent

        PlaygroundPage ->
            Page.Playground.view model.theme

        SettingsPage ->
            Page.Settings.view
                (settingsViewData model)
                model.theme
                |> Element.map GotSettingsIntent

        NotFoundPage ->
            Element.el
                [ Element.width Element.fill
                , Element.padding 20
                ]
                (Element.text "Not Found")


viewThemeToggle : Theme -> Element.Element Msg
viewThemeToggle theme =
    let
        toggleText =
            case theme of
                Light ->
                    "Dark"

                Dark ->
                    "Light"
    in
    Input.button
        [ Element.padding 10
        , Element.spacing 5
        , Background.color
            (case theme of
                Light ->
                    Theme.getColors Dark |> .primary

                Dark ->
                    Theme.getColors Light |> .primary
            )
        , Font.color
            (Theme.getColors theme |> .text)
        ]
        { onPress = Just ThemeToggled
        , label = Element.text toggleText
        }



-- Helper functions


themeBackgroundCss : Theme -> String
themeBackgroundCss theme =
    case theme of
        Light ->
            "rgb(250, 250, 252)"

        Dark ->
            "rgb(18, 18, 18)"


playersViewData : Model -> Page.Players.ViewData
playersViewData model =
    { players = model.players
    , initialBuyIn = model.initialBuyIn
    , newPlayerName = model.newPlayerName
    , playerListCollapsed = model.playerListCollapsed
    }


gameViewData : Model -> Page.Game.ViewData
gameViewData model =
    { chips =
        model.settings.chipSettings
            |> List.filter .enabled
            |> List.map (\cs -> Page.Game.Chip cs.color cs.value)
    , blindLevels = model.blindLevels
    , blindDuration = model.blindDuration
    , blindDurationInput = model.blindDurationInput
    , remainingTime = model.remainingTime
    , timerState = model.timerState
    , activeRankingIndex = model.activeRankingIndex
    , selectedPlayerForBuyIn = model.selectedPlayerForBuyIn
    , roster = List.map .player model.players
    , initialBuyIn = model.initialBuyIn
    , buyIns = model.buyIns
    , buyInTimerDuration = model.buyInTimerDuration
    , buyInTimerDurationInput = model.buyInTimerDurationInput
    , buyInRemainingTime = model.buyInRemainingTime
    , buyInTimerState = model.buyInTimerState
    , buyInListCollapsed = model.buyInListCollapsed
    }


settingsViewData : Model -> Page.Settings.ViewData
settingsViewData model =
    { chipSettings =
        List.map
            (\cs ->
                { color = cs.color
                , value = cs.value
                , valueInput = cs.valueInput
                , enabled = cs.enabled
                }
            )
            model.settings.chipSettings
    , blindLevelSettings = model.settings.blindLevelSettings
    }


defaultBlindLevelSettings : List Page.Settings.BlindLevelSetting
defaultBlindLevelSettings =
    [ { smallBlind = 100, bigBlind = 200, smallBlindInput = "100", bigBlindInput = "200" }
    , { smallBlind = 200, bigBlind = 400, smallBlindInput = "200", bigBlindInput = "400" }
    , { smallBlind = 300, bigBlind = 600, smallBlindInput = "300", bigBlindInput = "600" }
    , { smallBlind = 400, bigBlind = 800, smallBlindInput = "400", bigBlindInput = "800" }
    , { smallBlind = 500, bigBlind = 1000, smallBlindInput = "500", bigBlindInput = "1000" }
    , { smallBlind = 800, bigBlind = 1600, smallBlindInput = "800", bigBlindInput = "1600" }
    , { smallBlind = 1000, bigBlind = 2000, smallBlindInput = "1000", bigBlindInput = "2000" }
    , { smallBlind = 2000, bigBlind = 4000, smallBlindInput = "2000", bigBlindInput = "4000" }
    ]


blindLevelsFromSettings : List Page.Settings.BlindLevelSetting -> Page.Game.BlindLevels
blindLevelsFromSettings settings =
    let
        blinds =
            List.map (\s -> { smallBlind = s.smallBlind, bigBlind = s.bigBlind }) settings
    in
    case Page.Game.blindLevelsFromList blinds of
        Just levels ->
            levels

        Nothing ->
            Page.Game.defaultBlindLevels


championViewData : Model -> Page.Champion.ViewData
championViewData model =
    let
        currentRoster =
            List.map .player model.players

        totalPot =
            (List.length currentRoster + List.length model.buyIns) * model.initialBuyIn
    in
    { winnerFlow = model.winnerFlow
    , players = currentRoster
    , totalPot = totalPot
    , buyInPlayers = model.buyIns
    , initialBuyIn = model.initialBuyIn
    }


isActive : { link : Route, activePage : Page } -> Bool
isActive { link, activePage } =
    case ( link, activePage ) of
        ( Home, HomePage ) ->
            True

        ( Home, _ ) ->
            False

        ( Players, PlayersPage ) ->
            True

        ( Players, _ ) ->
            False

        ( Game, GamePage ) ->
            True

        ( Game, _ ) ->
            False

        ( Champion, ChampionPage ) ->
            True

        ( Champion, _ ) ->
            False

        ( Playground, PlaygroundPage ) ->
            True

        ( Playground, _ ) ->
            False

        ( Settings, SettingsPage ) ->
            True

        ( Settings, _ ) ->
            False


routeParser : Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map Home top
        , Url.Parser.map Players (s "players")
        , Url.Parser.map Game (s "game")
        , Url.Parser.map Champion (s "champion")
        , Url.Parser.map Playground (s "playground")
        , Url.Parser.map Settings (s "settings")
        ]


routeToPath : Route -> String
routeToPath route =
    case route of
        Home ->
            "/"

        Players ->
            "/players"

        Game ->
            "/game"

        Champion ->
            "/champion"

        Playground ->
            "/playground"

        Settings ->
            "/settings"


routeToString : Route -> String
routeToString route =
    case route of
        Home ->
            "Home"

        Players ->
            "Players"

        Game ->
            "Game"

        Champion ->
            "Champion"

        Playground ->
            "Playground"

        Settings ->
            "Settings"


onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest urlRequest =
    ClickedLink urlRequest


onUrlChange : Url -> Msg
onUrlChange url =
    ChangedUrl url


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
