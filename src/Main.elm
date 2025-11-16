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
import Theme exposing (Theme(..))
import Url exposing (Url)
import Url.Parser exposing ((</>), Parser, s, top)



-- MODEL


type alias Model =
    { page : Page
    , theme : Theme
    , navigationKey : Navigation.Key
    }


type Route
    = Home
    | Players
    | Game
    | Champion


type Page
    = HomePage Page.Home.Model
    | PlayersPage Page.Players.Model
    | GamePage Page.Game.Model
    | ChampionPage Page.Champion.Model
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
                    toPlayers model (Page.Players.update playersMsg players)

                _ ->
                    ( model, Cmd.none )

        GotGameMsg gameMsg ->
            case model.page of
                GamePage game ->
                    toGame model (Page.Game.update gameMsg game)

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
    ( { model | page = PlayersPage players }
    , Cmd.map GotPlayersMsg cmd
    )


toGame : Model -> ( Page.Game.Model, Cmd Page.Game.Msg ) -> ( Model, Cmd Msg )
toGame model ( game, cmd ) =
    ( { model | page = GamePage game }
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
            ( Page.Players.init, Cmd.none )
                |> toPlayers model

        Just Game ->
            ( Page.Game.init, Cmd.none )
                |> toGame model

        Just Champion ->
            ( Page.Champion.init, Cmd.none )
                |> toChampion model

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url key =
    updateUrl url { page = NotFound, theme = Theme.defaultTheme, navigationKey = key }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
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
                    , viewNavigation colors model.page
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
viewNavigation colors page =
    Element.row
        [ Element.spacing 15
        ]
        [ navButton colors Home page
        , navButton colors Players page
        , navButton colors Game page
        , navButton colors Champion page
        ]


navButton : Theme.ColorPalette -> Route -> Page -> Element.Element Msg
navButton colors route page =
    let
        active =
            isActive { link = route, page = page }

        attributes =
            [ Element.padding 10
            , Element.spacing 5
            , Background.color colors.primary
            , Font.color colors.text
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
            (case theme of
                Light ->
                    Theme.getColors Dark |> .text

                Dark ->
                    Theme.getColors Light |> .text
            )
        ]
        { onPress = Just ThemeToggled
        , label = Element.text toggleText
        }



-- Helper functions


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


routeParser : Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map Home top
        , Url.Parser.map Players (s "players")
        , Url.Parser.map Game (s "game")
        , Url.Parser.map Champion (s "champion")
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
