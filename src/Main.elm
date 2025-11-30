module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Element
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Page.Champion
import Page.Game
import Page.Home
import Page.Players
import Page.Playground
import Ports
import Theme exposing (Theme(..))
import Url exposing (Url)
import Url.Parser exposing ((</>), Parser, s, top)



-- MODEL


type alias Model =
    { page : Page
    , theme : Theme
    , navigationKey : Navigation.Key
    , basePath : String
    , home : Page.Home.Model
    , players : Page.Players.Model
    , game : Page.Game.Model
    , champion : Page.Champion.Model
    }


type Route
    = Home
    | Players
    | Game
    | Champion
    | Playground


type Page
    = HomePage
    | PlayersPage
    | GamePage
    | ChampionPage
    | PlaygroundPage
    | NotFound



-- UPDATE


type Msg
    = ClickedLink Browser.UrlRequest
    | ChangedUrl Url
    | GotHomeMsg Page.Home.Msg
    | GotPlayersMsg Page.Players.Msg
    | GotGameMsg Page.Game.Msg
    | GotChampionMsg Page.Champion.Msg
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

        GotHomeMsg homeMsg ->
            case model.page of
                HomePage ->
                    let
                        ( updatedHome, cmd ) =
                            Page.Home.update homeMsg model.home
                    in
                    ( { model | home = updatedHome }
                    , Cmd.map GotHomeMsg cmd
                    )

                _ ->
                    ( model, Cmd.none )

        GotPlayersMsg playersMsg ->
            case model.page of
                PlayersPage ->
                    let
                        ( updatedPlayers, cmd ) =
                            Page.Players.update playersMsg model.players

                        syncedGame =
                            Page.Game.init
                                (Just model.game)
                                (playersRoster updatedPlayers)
                                updatedPlayers.initialBuyIn
                    in
                    ( { model
                        | players = updatedPlayers
                        , game = syncedGame
                      }
                    , Cmd.map GotPlayersMsg cmd
                    )

                _ ->
                    ( model, Cmd.none )

        GotGameMsg gameMsg ->
            case model.page of
                GamePage ->
                    let
                        ( updatedGame, cmd ) =
                            Page.Game.update gameMsg model.game
                    in
                    ( { model | game = updatedGame }
                    , Cmd.map GotGameMsg cmd
                    )

                _ ->
                    ( model, Cmd.none )

        GotChampionMsg championMsg ->
            case model.page of
                ChampionPage ->
                    let
                        ( updatedChampion, cmd ) =
                            Page.Champion.update championMsg model.champion
                    in
                    ( { model | champion = updatedChampion }
                    , Cmd.map GotChampionMsg cmd
                    )

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
            ( { model | page = HomePage }, Cmd.none )

        Just Players ->
            ( { model | page = PlayersPage }, Cmd.none )

        Just Game ->
            let
                syncedGame =
                    Page.Game.init
                        (Just model.game)
                        (playersRoster model.players)
                        model.players.initialBuyIn
            in
            ( { model | page = GamePage, game = syncedGame }, Cmd.none )

        Just Champion ->
            ( { model
                | page = ChampionPage
                , champion = buildChampionModel model
              }
            , Cmd.none
            )

        Just Playground ->
            ( { model | page = PlaygroundPage }, Cmd.none )

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        basePath =
            detectBasePath url

        initialHome =
            Page.Home.init

        initialPlayers =
            Page.Players.init Nothing

        initialGame =
            Page.Game.init Nothing (playersRoster initialPlayers) initialPlayers.initialBuyIn

        initialChampion =
            Page.Champion.init [] 0 [] initialPlayers.initialBuyIn

        initialModel =
            { page = NotFound
            , theme = Theme.defaultTheme
            , navigationKey = key
            , basePath = basePath
            , home = initialHome
            , players = initialPlayers
            , game = initialGame
            , champion = initialChampion
            }
    in
    updateUrl url initialModel



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        pageSubscriptions =
            case model.page of
                GamePage ->
                    Sub.map GotGameMsg (Page.Game.subscriptions model.game)

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
        [ Element.layout
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
                    , viewNavigation colors model.page model.basePath
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


viewNavigation : Theme.ColorPalette -> Page -> String -> Element.Element Msg
viewNavigation colors page basePath =
    Element.row
        [ Element.spacing 15
        ]
        [ navButton colors Home page basePath
        , navButton colors Players page basePath
        , navButton colors Game page basePath
        , navButton colors Champion page basePath
        ]


navButton : Theme.ColorPalette -> Route -> Page -> String -> Element.Element Msg
navButton colors route page basePath =
    let
        active =
            isActive { link = route, page = page }

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
        { url = routeToPath basePath route
        , label = Element.text ("[ " ++ routeToString route ++ " ]")
        }


viewPageContent : Model -> Element.Element Msg
viewPageContent model =
    case model.page of
        HomePage ->
            Page.Home.view model.home model.theme
                |> Element.map GotHomeMsg

        PlayersPage ->
            Page.Players.view model.players model.theme
                |> Element.map GotPlayersMsg

        GamePage ->
            Page.Game.view model.game model.theme
                |> Element.map GotGameMsg

        ChampionPage ->
            Page.Champion.view model.champion model.theme
                |> Element.map GotChampionMsg

        PlaygroundPage ->
            Page.Playground.view model.theme

        NotFound ->
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


playersRoster : Page.Players.Model -> List Page.Players.Player
playersRoster =
    Page.Players.roster


buildChampionModel : Model -> Page.Champion.Model
buildChampionModel model =
    let
        roster =
            playersRoster model.players

        buyIns =
            model.game.buyIns

        initialBuyIn =
            model.players.initialBuyIn

        totalPot =
            (List.length roster + List.length buyIns) * initialBuyIn

        championBuyInPlayers =
            Page.Game.buyInPlayers buyIns
    in
    Page.Champion.init roster totalPot championBuyInPlayers initialBuyIn


detectBasePath : Url -> String
detectBasePath url =
    if String.startsWith "/elm-poker" url.path then
        "/elm-poker"

    else
        ""


isActive : { link : Route, page : Page } -> Bool
isActive { link, page } =
    case ( link, page ) of
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


routeParserLocal : Parser (Route -> a) a
routeParserLocal =
    Url.Parser.oneOf
        [ Url.Parser.map Home top
        , Url.Parser.map Players (s "players")
        , Url.Parser.map Game (s "game")
        , Url.Parser.map Champion (s "champion")
        , Url.Parser.map Playground (s "playground")
        ]


routeParserWithBase : Parser (Route -> a) a
routeParserWithBase =
    Url.Parser.oneOf
        [ Url.Parser.map Home (s "elm-poker" </> top)
        , Url.Parser.map Players (s "elm-poker" </> s "players")
        , Url.Parser.map Game (s "elm-poker" </> s "game")
        , Url.Parser.map Champion (s "elm-poker" </> s "champion")
        , Url.Parser.map Playground (s "elm-poker" </> s "playground")
        ]


routeParser : Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ routeParserWithBase
        , routeParserLocal
        ]


routeToPath : String -> Route -> String
routeToPath basePath route =
    let
        path =
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
    in
    basePath ++ path


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
