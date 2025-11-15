module Main exposing (main)

import Browser exposing (UrlRequest)
import Element
import Element.Input as Input
import Url exposing (Url)


type alias Model =
    { value : String }


type Msg
    = NoOp
    | NavigateTo String


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
                , Element.row
                    [ Element.width Element.fill
                    , Element.padding 15
                    , Element.spacing 15
                    ]
                    [ navButton "Home"
                    , navButton "Players"
                    , navButton "Game"
                    , navButton "Champion"
                    ]

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


navButton : String -> Element.Element Msg
navButton label =
    Input.button
        [ Element.padding 10
        , Element.spacing 5
        ]
        { onPress = Just (NavigateTo label)
        , label = Element.text ("[ " ++ label ++ " ]")
        }


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
