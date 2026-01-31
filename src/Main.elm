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
    { -- Persistent page models (data shared across pages)
      players : Page.Players.Model
    , game : Page.Game.Model

    -- Global state
    , theme : Theme
    , navigationKey : Navigation.Key
    , basePath : String

    -- Active page (eliminates impossible page/model mismatch)
    , activePage : Page
    }


{-| Page combines the page indicator with any page-specific transient state.
Champion model is transient (rebuilt on each navigation), while Players and Game
models persist in the top-level Model.
-}
type Page
    = HomePage
    | PlayersPage
    | GamePage
    | ChampionPage Page.Champion.Model
    | PlaygroundPage
    | NotFoundPage


type Route
    = Home
    | Players
    | Game
    | Champion
    | Playground



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

        GotHomeMsg _ ->
            -- Home page has no real state to update
            ( model, Cmd.none )

        GotPlayersMsg playersMsg ->
            case model.activePage of
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
            case model.activePage of
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
            case model.activePage of
                ChampionPage championModel ->
                    let
                        ( updatedChampion, cmd ) =
                            Page.Champion.update championMsg championModel
                    in
                    ( { model | activePage = ChampionPage updatedChampion }
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
            ( { model | activePage = HomePage }, Cmd.none )

        Just Players ->
            ( { model | activePage = PlayersPage }, Cmd.none )

        Just Game ->
            let
                syncedGame =
                    Page.Game.init
                        (Just model.game)
                        (playersRoster model.players)
                        model.players.initialBuyIn
            in
            ( { model | activePage = GamePage, game = syncedGame }, Cmd.none )

        Just Champion ->
            ( { model | activePage = ChampionPage (buildChampionModel model) }
            , Cmd.none
            )

        Just Playground ->
            ( { model | activePage = PlaygroundPage }, Cmd.none )

        Nothing ->
            ( { model | activePage = NotFoundPage }, Cmd.none )


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        basePath =
            detectBasePath url

        initialPlayers =
            Page.Players.init Nothing

        initialGame =
            Page.Game.init Nothing (playersRoster initialPlayers) initialPlayers.initialBuyIn

        initialModel =
            { players = initialPlayers
            , game = initialGame
            , theme = Theme.defaultTheme
            , navigationKey = key
            , basePath = basePath
            , activePage = NotFoundPage
            }
    in
    updateUrl url initialModel



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        pageSubscriptions =
            case model.activePage of
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
                    , viewNavigation colors model.activePage model.basePath
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
viewNavigation colors activePage basePath =
    Element.row
        [ Element.spacing 15
        ]
        [ navButton colors Home activePage basePath
        , navButton colors Players activePage basePath
        , navButton colors Game activePage basePath
        , navButton colors Champion activePage basePath
        ]


navButton : Theme.ColorPalette -> Route -> Page -> String -> Element.Element Msg
navButton colors route activePage basePath =
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
        { url = routeToPath basePath route
        , label = Element.text ("[ " ++ routeToString route ++ " ]")
        }


viewPageContent : Model -> Element.Element Msg
viewPageContent model =
    case model.activePage of
        HomePage ->
            Page.Home.view Page.Home.init model.theme
                |> Element.map GotHomeMsg

        PlayersPage ->
            Page.Players.view model.players model.theme
                |> Element.map GotPlayersMsg

        GamePage ->
            Page.Game.view model.game model.theme
                |> Element.map GotGameMsg

        ChampionPage championModel ->
            Page.Champion.view championModel model.theme
                |> Element.map GotChampionMsg

        PlaygroundPage ->
            Page.Playground.view model.theme

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

        ( Champion, ChampionPage _ ) ->
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
