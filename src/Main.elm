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
import Theme exposing (Theme(..))
import Url exposing (Url)
import Url.Parser exposing ((</>), Parser, s, top)



-- MODEL


type alias Model =
    { page : Page
    , theme : Theme
    , navigationKey : Navigation.Key
    , playersPageState : Maybe Page.Players.Model
    , gamePageState : Maybe Page.Game.Model
    , basePath : String
    }


type Route
    = Home
    | Players
    | Game
    | Champion
    | Playground


type Page
    = HomePage Page.Home.Model
    | PlayersPage Page.Players.Model
    | GamePage Page.Game.Model
    | ChampionPage Page.Champion.Model
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
                HomePage home ->
                    toHome model (Page.Home.update homeMsg home)

                _ ->
                    ( model, Cmd.none )

        GotPlayersMsg playersMsg ->
            case model.page of
                PlayersPage players ->
                    let
                        ( updatedPlayers, cmd ) =
                            Page.Players.update playersMsg players
                    in
                    ( { model
                        | page = PlayersPage updatedPlayers
                        , playersPageState = Just updatedPlayers
                      }
                    , Cmd.map GotPlayersMsg cmd
                    )

                _ ->
                    ( model, Cmd.none )

        GotGameMsg gameMsg ->
            case model.page of
                GamePage game ->
                    toGame model model.playersPageState (Page.Game.update gameMsg game)

                _ ->
                    ( model, Cmd.none )

        GotChampionMsg championMsg ->
            case model.page of
                ChampionPage champion ->
                    toChampion model (Page.Champion.update championMsg champion)

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


toHome : Model -> ( Page.Home.Model, Cmd Page.Home.Msg ) -> ( Model, Cmd Msg )
toHome model ( home, cmd ) =
    ( { model | page = HomePage home }
    , Cmd.map GotHomeMsg cmd
    )


toPlayers : Model -> ( Page.Players.Model, Cmd Page.Players.Msg ) -> ( Model, Cmd Msg )
toPlayers model ( players, cmd ) =
    ( { model
        | page = PlayersPage players
        , playersPageState = Just players
      }
    , Cmd.map GotPlayersMsg cmd
    )


toGame : Model -> Maybe Page.Players.Model -> ( Page.Game.Model, Cmd Page.Game.Msg ) -> ( Model, Cmd Msg )
toGame model maybePlayersModel ( game, cmd ) =
    let
        extractedPlayers =
            case maybePlayersModel of
                Just playersModel ->
                    playersModel.players

                Nothing ->
                    []

        extractedBuyIn =
            case maybePlayersModel of
                Just playersModel ->
                    playersModel.initialBuyIn

                Nothing ->
                    0

        updatedGame =
            Page.Game.init (Just game) extractedPlayers extractedBuyIn
    in
    ( { model
        | page = GamePage updatedGame
        , gamePageState = Just updatedGame
      }
    , Cmd.map GotGameMsg cmd
    )


toChampion : Model -> ( Page.Champion.Model, Cmd Page.Champion.Msg ) -> ( Model, Cmd Msg )
toChampion model ( champion, cmd ) =
    ( { model | page = ChampionPage champion }
    , Cmd.map GotChampionMsg cmd
    )


updateUrl : Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Url.Parser.parse routeParser url of
        Just Home ->
            ( Page.Home.init, Cmd.none )
                |> toHome model

        Just Players ->
            ( Page.Players.init model.playersPageState, Cmd.none )
                |> toPlayers model

        Just Game ->
            ( Page.Game.init model.gamePageState [] 0, Cmd.none )
                |> toGame model model.playersPageState

        Just Champion ->
            let
                extractedPlayers =
                    case model.playersPageState of
                        Just playersModel ->
                            playersModel.players

                        Nothing ->
                            []

                extractedBuyIn =
                    case model.playersPageState of
                        Just playersModel ->
                            playersModel.initialBuyIn

                        Nothing ->
                            0

                extractedBuyIns =
                    case model.gamePageState of
                        Just gameModel ->
                            gameModel.buyIns

                        Nothing ->
                            []

                totalPot =
                    (List.length extractedPlayers + List.length extractedBuyIns) * extractedBuyIn

                -- Extract players from buy-ins
                championBuyInPlayers =
                    Page.Game.buyInPlayers extractedBuyIns

                championModel =
                    Page.Champion.init extractedPlayers totalPot championBuyInPlayers extractedBuyIn
            in
            ( championModel, Cmd.none )
                |> toChampion model

        Just Playground ->
            ( { model | page = PlaygroundPage }, Cmd.none )

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        basePath =
            detectBasePath url

        initialModel =
            { page = NotFound
            , theme = Theme.defaultTheme
            , navigationKey = key
            , playersPageState = Nothing
            , gamePageState = Nothing
            , basePath = basePath
            }
    in
    updateUrl url initialModel



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        GamePage game ->
            Sub.map GotGameMsg (Page.Game.subscriptions game)

        _ ->
            Sub.none



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
        HomePage home ->
            Page.Home.view home model.theme
                |> Element.map GotHomeMsg

        PlayersPage players ->
            Page.Players.view players model.theme
                |> Element.map GotPlayersMsg

        GamePage game ->
            Page.Game.view game model.theme
                |> Element.map GotGameMsg

        ChampionPage champion ->
            Page.Champion.view champion model.theme
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


detectBasePath : Url -> String
detectBasePath url =
    if String.startsWith "/elm-poker" url.path then
        "/elm-poker"

    else
        ""


isActive : { link : Route, page : Page } -> Bool
isActive { link, page } =
    case ( link, page ) of
        ( Home, HomePage _ ) ->
            True

        ( Home, _ ) ->
            False

        ( Players, PlayersPage _ ) ->
            True

        ( Players, _ ) ->
            False

        ( Game, GamePage _ ) ->
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
