module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Char
import Element
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import File exposing (File)
import File.Download
import File.Select
import Html
import Json.Decode as Decode
import Json.Encode as Encode
import Marquee
import Page.Champion
import Page.Game
import Page.Home
import Page.Players
import Page.Playground
import Page.Settings
import Player exposing (Player(..))
import Ports
import Random
import Task
import Theme exposing (Theme(..))
import Url exposing (Url)
import Url.Parser exposing (Parser, s, top)



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


type alias AppSettings =
    { chipSettings : List ChipSetting
    , blindLevelSettings : List Page.Settings.BlindLevelSetting
    , playerCount : Int
    , playerCountInput : String
    , animateGameChips : Bool
    , marqueeFontSizePx : Int
    , rebuyAmount : Page.Settings.RebuyAmount
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
    | GotSettingsFile File
    | GotSettingsFileContent String


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

        GotSettingsFile file ->
            ( model, Task.perform GotSettingsFileContent (File.toString file) )

        GotSettingsFileContent content ->
            case Decode.decodeString decodeAppSettings content of
                Ok importedSettings ->
                    ( { model
                        | settings = importedSettings
                        , blindLevels = blindLevelsFromSettings importedSettings.blindLevelSettings
                      }
                    , saveSettings importedSettings
                    )

                Err _ ->
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


init : Decode.Value -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        savedSettings =
            Decode.decodeValue decodeAppSettings flags
                |> Result.toMaybe

        settings =
            savedSettings
                |> Maybe.withDefault defaultSettings

        initialBlindDuration =
            12 * 60

        initialBuyInTimerDuration =
            30 * 60

        initialModel =
            { navigationKey = key
            , activePage = NotFoundPage
            , theme = Theme.defaultTheme
            , settings = settings

            -- Players
            , players = []
            , initialBuyIn = 0
            , newPlayerName = ""
            , playerListCollapsed = False

            -- Game
            , blindLevels = blindLevelsFromSettings settings.blindLevelSettings
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


defaultSettings : AppSettings
defaultSettings =
    { chipSettings =
        [ { color = Page.Game.White, value = 5, valueInput = "5", startingQuantity = 20, startingQuantityInput = "20", ownedQuantity = 200, ownedQuantityInput = "200", enabled = True }
        , { color = Page.Game.Red, value = 10, valueInput = "10", startingQuantity = 15, startingQuantityInput = "15", ownedQuantity = 150, ownedQuantityInput = "150", enabled = True }
        , { color = Page.Game.Green, value = 25, valueInput = "25", startingQuantity = 10, startingQuantityInput = "10", ownedQuantity = 100, ownedQuantityInput = "100", enabled = True }
        , { color = Page.Game.Blue, value = 50, valueInput = "50", startingQuantity = 8, startingQuantityInput = "8", ownedQuantity = 100, ownedQuantityInput = "100", enabled = True }
        , { color = Page.Game.Black, value = 100, valueInput = "100", startingQuantity = 6, startingQuantityInput = "6", ownedQuantity = 100, ownedQuantityInput = "100", enabled = True }
        ]
    , blindLevelSettings = defaultBlindLevelSettings
    , playerCount = 8
    , playerCountInput = "8"
    , animateGameChips = True
    , marqueeFontSizePx = Marquee.defaultFontSizePx
    , rebuyAmount = Page.Settings.FullRebuy
    }



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


saveSettings : AppSettings -> Cmd msg
saveSettings settings =
    Ports.send (Ports.SaveSettings (encodeAppSettings settings))


sanitizeNumericInput : String -> String
sanitizeNumericInput input =
    String.filter Char.isDigit input


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

                updatedSettings =
                    { settings | chipSettings = updatedChipSettings }
            in
            ( { model | settings = updatedSettings }
            , saveSettings updatedSettings
            )

        Page.Settings.ChipValueChanged targetColor str ->
            let
                sanitizedInput =
                    sanitizeNumericInput str

                updatedChipSettings =
                    List.map
                        (\cs ->
                            if cs.color == targetColor then
                                case String.toInt sanitizedInput of
                                    Just v ->
                                        { cs | valueInput = sanitizedInput, value = v }

                                    Nothing ->
                                        { cs | valueInput = sanitizedInput }

                            else
                                cs
                        )
                        chipSettings

                updatedSettings =
                    { settings | chipSettings = updatedChipSettings }
            in
            ( { model | settings = updatedSettings }
            , saveSettings updatedSettings
            )

        Page.Settings.ChipStartingQuantityChanged targetColor str ->
            let
                sanitizedInput =
                    sanitizeNumericInput str

                updatedChipSettings =
                    List.map
                        (\cs ->
                            if cs.color == targetColor then
                                case String.toInt sanitizedInput of
                                    Just v ->
                                        { cs | startingQuantityInput = sanitizedInput, startingQuantity = v }

                                    Nothing ->
                                        { cs | startingQuantityInput = sanitizedInput, startingQuantity = 0 }

                            else
                                cs
                        )
                        chipSettings

                updatedSettings =
                    { settings | chipSettings = updatedChipSettings }
            in
            ( { model | settings = updatedSettings }
            , saveSettings updatedSettings
            )

        Page.Settings.ChipOwnedQuantityChanged targetColor str ->
            let
                sanitizedInput =
                    sanitizeNumericInput str

                updatedChipSettings =
                    List.map
                        (\cs ->
                            if cs.color == targetColor then
                                case String.toInt sanitizedInput of
                                    Just v ->
                                        { cs | ownedQuantityInput = sanitizedInput, ownedQuantity = v }

                                    Nothing ->
                                        { cs | ownedQuantityInput = sanitizedInput, ownedQuantity = 0 }

                            else
                                cs
                        )
                        chipSettings

                updatedSettings =
                    { settings | chipSettings = updatedChipSettings }
            in
            ( { model | settings = updatedSettings }
            , saveSettings updatedSettings
            )

        Page.Settings.GameChipAnimationToggled ->
            let
                updatedSettings =
                    { settings | animateGameChips = not settings.animateGameChips }
            in
            ( { model | settings = updatedSettings }
            , saveSettings updatedSettings
            )

        Page.Settings.MarqueeFontSizeDecreased ->
            let
                updatedSettings =
                    { settings
                        | marqueeFontSizePx =
                            Marquee.clampMarqueeFontSizePx (settings.marqueeFontSizePx - Marquee.marqueeFontSizeStep)
                    }
            in
            ( { model | settings = updatedSettings }
            , saveSettings updatedSettings
            )

        Page.Settings.MarqueeFontSizeIncreased ->
            let
                updatedSettings =
                    { settings
                        | marqueeFontSizePx =
                            Marquee.clampMarqueeFontSizePx (settings.marqueeFontSizePx + Marquee.marqueeFontSizeStep)
                    }
            in
            ( { model | settings = updatedSettings }
            , saveSettings updatedSettings
            )

        Page.Settings.RebuyAmountChanged rebuyAmount ->
            let
                updatedSettings =
                    { settings | rebuyAmount = rebuyAmount }
            in
            ( { model | settings = updatedSettings }
            , saveSettings updatedSettings
            )

        Page.Settings.PlayerCountChanged str ->
            let
                sanitizedInput =
                    sanitizeNumericInput str

                updatedSettings =
                    case String.toInt sanitizedInput of
                        Just playerCount ->
                            { settings | playerCountInput = sanitizedInput, playerCount = playerCount }

                        Nothing ->
                            { settings | playerCountInput = sanitizedInput, playerCount = 0 }
            in
            ( { model | settings = updatedSettings }
            , saveSettings updatedSettings
            )

        Page.Settings.BlindSmallChanged targetIndex str ->
            let
                sanitizedInput =
                    sanitizeNumericInput str

                updatedBlindSettings =
                    List.indexedMap
                        (\i bl ->
                            if i == targetIndex then
                                case String.toInt sanitizedInput of
                                    Just v ->
                                        { bl | smallBlindInput = sanitizedInput, smallBlind = v }

                                    Nothing ->
                                        { bl | smallBlindInput = sanitizedInput }

                            else
                                bl
                        )
                        settings.blindLevelSettings

                updatedSettings =
                    { settings | blindLevelSettings = updatedBlindSettings }
            in
            ( { model
                | settings = updatedSettings
                , blindLevels = blindLevelsFromSettings updatedBlindSettings
              }
            , saveSettings updatedSettings
            )

        Page.Settings.BlindBigChanged targetIndex str ->
            let
                sanitizedInput =
                    sanitizeNumericInput str

                updatedBlindSettings =
                    List.indexedMap
                        (\i bl ->
                            if i == targetIndex then
                                case String.toInt sanitizedInput of
                                    Just v ->
                                        { bl | bigBlindInput = sanitizedInput, bigBlind = v }

                                    Nothing ->
                                        { bl | bigBlindInput = sanitizedInput }

                            else
                                bl
                        )
                        settings.blindLevelSettings

                updatedSettings =
                    { settings | blindLevelSettings = updatedBlindSettings }
            in
            ( { model
                | settings = updatedSettings
                , blindLevels = blindLevelsFromSettings updatedBlindSettings
              }
            , saveSettings updatedSettings
            )

        Page.Settings.ResetToDefaults ->
            ( { model
                | settings = defaultSettings
                , blindLevels = blindLevelsFromSettings defaultSettings.blindLevelSettings
              }
            , saveSettings defaultSettings
            )

        Page.Settings.ExportSettings ->
            let
                jsonString =
                    Encode.encode 2 (encodeAppSettings model.settings)
            in
            ( model
            , File.Download.string "elm-poker-settings.json" "application/json" jsonString
            )

        Page.Settings.ImportSettings ->
            ( model
            , File.Select.file [ "application/json" ] GotSettingsFile
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
    let
        enabledChipSettings =
            model.settings.chipSettings
                |> List.filter .enabled
    in
    { chips =
        enabledChipSettings
            |> List.map (\cs -> Page.Game.Chip cs.color cs.value)
    , chipQuantities =
        enabledChipSettings
            |> List.map
                (\cs ->
                    { color = cs.color
                    , quantity = cs.startingQuantity
                    }
                )
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
    , animateGameChips = model.settings.animateGameChips
    , marqueeFontSizePx = model.settings.marqueeFontSizePx
    , rebuyAmount = rebuyAmountValue model.settings.rebuyAmount model.initialBuyIn
    }


settingsViewData : Model -> Page.Settings.ViewData
settingsViewData model =
    { chipSettings =
        List.map
            (\cs ->
                { color = cs.color
                , value = cs.value
                , valueInput = cs.valueInput
                , startingQuantity = cs.startingQuantity
                , startingQuantityInput = cs.startingQuantityInput
                , ownedQuantity = cs.ownedQuantity
                , ownedQuantityInput = cs.ownedQuantityInput
                , enabled = cs.enabled
                }
            )
            model.settings.chipSettings
    , blindLevelSettings = model.settings.blindLevelSettings
    , playerCount = model.settings.playerCount
    , playerCountInput = model.settings.playerCountInput
    , animateGameChips = model.settings.animateGameChips
    , marqueeFontSizePx = model.settings.marqueeFontSizePx
    , rebuyAmount = model.settings.rebuyAmount
    }


defaultBlindLevelSettings : List Page.Settings.BlindLevelSetting
defaultBlindLevelSettings =
    [ { smallBlind = 5, bigBlind = 10, smallBlindInput = "5", bigBlindInput = "10" }
    , { smallBlind = 10, bigBlind = 20, smallBlindInput = "10", bigBlindInput = "20" }
    , { smallBlind = 15, bigBlind = 30, smallBlindInput = "15", bigBlindInput = "30" }
    , { smallBlind = 20, bigBlind = 40, smallBlindInput = "20", bigBlindInput = "40" }
    , { smallBlind = 25, bigBlind = 50, smallBlindInput = "25", bigBlindInput = "50" }
    , { smallBlind = 50, bigBlind = 100, smallBlindInput = "50", bigBlindInput = "100" }
    , { smallBlind = 75, bigBlind = 150, smallBlindInput = "75", bigBlindInput = "150" }
    , { smallBlind = 100, bigBlind = 200, smallBlindInput = "100", bigBlindInput = "200" }
    , { smallBlind = 150, bigBlind = 300, smallBlindInput = "150", bigBlindInput = "300" }
    , { smallBlind = 200, bigBlind = 400, smallBlindInput = "200", bigBlindInput = "400" }
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


rebuyAmountValue : Page.Settings.RebuyAmount -> Int -> Int
rebuyAmountValue rebuyAmount initialBuyIn =
    case rebuyAmount of
        Page.Settings.FullRebuy ->
            initialBuyIn

        Page.Settings.HalfRebuy ->
            initialBuyIn // 2


championViewData : Model -> Page.Champion.ViewData
championViewData model =
    let
        currentRoster =
            List.map .player model.players

        rebuyAmount =
            rebuyAmountValue model.settings.rebuyAmount model.initialBuyIn

        totalPot =
            (List.length currentRoster * model.initialBuyIn) + (List.length model.buyIns * rebuyAmount)
    in
    { winnerFlow = model.winnerFlow
    , players = currentRoster
    , totalPot = totalPot
    , buyInPlayers = model.buyIns
    , initialBuyIn = model.initialBuyIn
    , rebuyAmount = rebuyAmount
    }



-- JSON


encodeAppSettings : AppSettings -> Encode.Value
encodeAppSettings settings =
    Encode.object
        [ ( "chipSettings", Encode.list encodeChipSetting settings.chipSettings )
        , ( "blindLevelSettings", Encode.list encodeBlindLevelSetting settings.blindLevelSettings )
        , ( "playerCount", Encode.int settings.playerCount )
        , ( "animateGameChips", Encode.bool settings.animateGameChips )
        , ( "marqueeFontSizePx", Encode.int settings.marqueeFontSizePx )
        , ( "rebuyAmount", encodeRebuyAmount settings.rebuyAmount )
        ]


encodeChipSetting : ChipSetting -> Encode.Value
encodeChipSetting cs =
    Encode.object
        [ ( "color", encodeChipColor cs.color )
        , ( "value", Encode.int cs.value )
        , ( "startingQuantity", Encode.int cs.startingQuantity )
        , ( "ownedQuantity", Encode.int cs.ownedQuantity )
        , ( "enabled", Encode.bool cs.enabled )
        ]


encodeChipColor : Page.Game.ChipColor -> Encode.Value
encodeChipColor color =
    Encode.string
        (case color of
            Page.Game.White ->
                "White"

            Page.Game.Red ->
                "Red"

            Page.Game.Blue ->
                "Blue"

            Page.Game.Green ->
                "Green"

            Page.Game.Black ->
                "Black"
        )


encodeBlindLevelSetting : Page.Settings.BlindLevelSetting -> Encode.Value
encodeBlindLevelSetting bl =
    Encode.object
        [ ( "smallBlind", Encode.int bl.smallBlind )
        , ( "bigBlind", Encode.int bl.bigBlind )
        ]


encodeRebuyAmount : Page.Settings.RebuyAmount -> Encode.Value
encodeRebuyAmount rebuyAmount =
    Encode.string
        (case rebuyAmount of
            Page.Settings.FullRebuy ->
                "Full"

            Page.Settings.HalfRebuy ->
                "Half"
        )


decodeAppSettings : Decode.Decoder AppSettings
decodeAppSettings =
    Decode.map6
        (\chipSettings blindLevelSettings playerCount animateGameChips marqueeFontSizePx rebuyAmount ->
            { chipSettings = chipSettings
            , blindLevelSettings = blindLevelSettings
            , playerCount = playerCount
            , playerCountInput = String.fromInt playerCount
            , animateGameChips = animateGameChips
            , marqueeFontSizePx = Marquee.clampMarqueeFontSizePx marqueeFontSizePx
            , rebuyAmount = rebuyAmount
            }
        )
        (Decode.field "chipSettings" (Decode.list decodeChipSetting))
        (Decode.field "blindLevelSettings" (Decode.list decodeBlindLevelSetting))
        (Decode.field "playerCount" Decode.int)
        (Decode.oneOf
            [ Decode.field "animateGameChips" Decode.bool
            , Decode.succeed True
            ]
        )
        (Decode.oneOf
            [ Decode.field "marqueeFontSizePx" Decode.int
            , Decode.succeed Marquee.defaultFontSizePx
            ]
        )
        (Decode.oneOf
            [ Decode.field "rebuyAmount" decodeRebuyAmount
            , Decode.succeed Page.Settings.FullRebuy
            ]
        )


decodeChipSetting : Decode.Decoder ChipSetting
decodeChipSetting =
    Decode.map5
        (\color value startingQuantity ownedQuantity enabled ->
            { color = color
            , value = value
            , valueInput = String.fromInt value
            , startingQuantity = startingQuantity
            , startingQuantityInput = String.fromInt startingQuantity
            , ownedQuantity = ownedQuantity
            , ownedQuantityInput = String.fromInt ownedQuantity
            , enabled = enabled
            }
        )
        (Decode.field "color" decodeChipColor)
        (Decode.field "value" Decode.int)
        (Decode.field "startingQuantity" Decode.int)
        (Decode.field "ownedQuantity" Decode.int)
        (Decode.field "enabled" Decode.bool)


decodeChipColor : Decode.Decoder Page.Game.ChipColor
decodeChipColor =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "White" ->
                        Decode.succeed Page.Game.White

                    "Red" ->
                        Decode.succeed Page.Game.Red

                    "Blue" ->
                        Decode.succeed Page.Game.Blue

                    "Green" ->
                        Decode.succeed Page.Game.Green

                    "Black" ->
                        Decode.succeed Page.Game.Black

                    _ ->
                        Decode.fail ("Unknown chip color: " ++ str)
            )


decodeBlindLevelSetting : Decode.Decoder Page.Settings.BlindLevelSetting
decodeBlindLevelSetting =
    Decode.map2
        (\smallBlind bigBlind ->
            { smallBlind = smallBlind
            , bigBlind = bigBlind
            , smallBlindInput = String.fromInt smallBlind
            , bigBlindInput = String.fromInt bigBlind
            }
        )
        (Decode.field "smallBlind" Decode.int)
        (Decode.field "bigBlind" Decode.int)


decodeRebuyAmount : Decode.Decoder Page.Settings.RebuyAmount
decodeRebuyAmount =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "Full" ->
                        Decode.succeed Page.Settings.FullRebuy

                    "Half" ->
                        Decode.succeed Page.Settings.HalfRebuy

                    _ ->
                        Decode.fail ("Unknown rebuy amount: " ++ str)
            )


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


main : Program Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
