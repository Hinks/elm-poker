module Main exposing (main)

import Browser exposing (UrlRequest)
import Element
import Element.Input as Input
import Url exposing (Url)


type Route
    = Home
    | Players
    | Game
    | Champion


type alias Model =
    { value : String }


type Msg
    = NoOp
    | NavigateTo Route


init : Model
init =
    { value = "Hello, World cool" }


view : Model -> Browser.Document Msg
view model =
    { title = "PokerNight App"
    , body =
        [ Element.layout
            []
            (Element.column
                [ Element.width Element.fill
                , Element.spacing 0
                ]
                [ -- Title row
                  Element.row
                    [ Element.width Element.fill
                    , Element.padding 20
                    , Element.spacing 0
                    ]
                    [ Element.text "PokerNight App" ]

                -- Navigation row
                , viewNavigation

                -- Content area
                , Element.el
                    [ Element.width Element.fill
                    , Element.padding 20
                    ]
                    (Element.text model.value)
                ]
            )
        ]
    }


viewNavigation : Element.Element Msg
viewNavigation =
    Element.row
        [ Element.width Element.fill
        , Element.padding 15
        , Element.spacing 15
        ]
        [ navButton Home
        , navButton Players
        , navButton Game
        , navButton Champion
        ]


navButton : Route -> Element.Element Msg
navButton route =
    Input.button
        [ Element.padding 10
        , Element.spacing 5
        ]
        { onPress = Just (NavigateTo route)
        , label = Element.text ("[ " ++ routeToString route ++ " ]")
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
