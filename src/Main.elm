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


type Route
    = Home
    | Players
    | Game
    | Champion


type alias Model =
    { currentRoute : Route
    , theme : Theme
    , navigationKey : Navigation.Key
    }


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { currentRoute = parseRoute url
      , theme = Theme.defaultTheme
      , navigationKey = key
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | NavigateTo Route
    | RouteChanged Route
    | ThemeToggled


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        NavigateTo route ->
            ( model
            , Navigation.pushUrl model.navigationKey (routeToPath route)
            )

        RouteChanged route ->
            ( { model | currentRoute = route }
            , Cmd.none
            )

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
                    , viewNavigation colors
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


viewNavigation : Theme.ColorPalette -> Element.Element Msg
viewNavigation colors =
    Element.row
        [ Element.spacing 15
        ]
        [ navButton colors Home
        , navButton colors Players
        , navButton colors Game
        , navButton colors Champion
        ]


navButton : Theme.ColorPalette -> Route -> Element.Element Msg
navButton colors route =
    Input.button
        [ Element.padding 10
        , Element.spacing 5
        , Background.color colors.primary
        , Font.color colors.text
        ]
        { onPress = Just (NavigateTo route)
        , label = Element.text ("[ " ++ routeToString route ++ " ]")
        }


viewPageContent : Model -> Element.Element Msg
viewPageContent model =
    case model.currentRoute of
        Home ->
            Page.Home.view model.theme

        Players ->
            Page.Players.view model.theme

        Game ->
            Page.Game.view model.theme

        Champion ->
            Page.Champion.view model.theme


viewThemeToggle : Theme -> Element.Element Msg
viewThemeToggle theme =
    let
        toggleText =
            case theme of
                Light ->
                    "🌙 Dark"

                Dark ->
                    "☀️ Light"
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


routeParser : Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map Home top
        , Url.Parser.map Players (s "players")
        , Url.Parser.map Game (s "game")
        , Url.Parser.map Champion (s "champion")
        ]


parseRoute : Url -> Route
parseRoute url =
    Maybe.withDefault Home (Url.Parser.parse routeParser url)


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
    case urlRequest of
        Browser.Internal url ->
            NavigateTo (parseRoute url)

        Browser.External _ ->
            NoOp


onUrlChange : Url -> Msg
onUrlChange url =
    RouteChanged (parseRoute url)


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
