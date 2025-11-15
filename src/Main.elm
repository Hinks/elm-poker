module Main exposing (main)

import Browser exposing (UrlRequest)
import Element
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Theme exposing (Theme(..))
import Url exposing (Url)


type Route
    = Home
    | Players
    | Game
    | Champion


type alias Model =
    { value : String
    , theme : Theme
    }


type Msg
    = NoOp
    | NavigateTo Route
    | ThemeToggled


init : Model
init =
    { value = "Hello, World cool"
    , theme = Theme.defaultTheme
    }


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
                , Element.el
                    [ Element.width Element.fill
                    , Element.padding 20
                    , Font.color colors.text
                    ]
                    (Element.text model.value)
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        NavigateTo route ->
            -- Placeholder for navigation - can be wired to routing later
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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


onUrlRequest : UrlRequest -> Msg
onUrlRequest urlRequest =
    NoOp


onUrlChange : Url -> Msg
onUrlChange url =
    NoOp


main : Program () Model Msg
main =
    Browser.application
        { init = \flags url key -> ( init, Cmd.none )
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
